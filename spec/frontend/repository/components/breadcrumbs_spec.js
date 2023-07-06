import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import Breadcrumbs from '~/repository/components/breadcrumbs.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';

import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';

import createApolloProvider from 'helpers/mock_apollo_helper';
import { __ } from '~/locale';

const defaultMockRoute = {
  name: 'blobPath',
};

const TEST_PROJECT_PATH = 'test-project/path';

Vue.use(VueApollo);

describe('Repository breadcrumbs component', () => {
  let wrapper;
  let permissionsQuerySpy;

  const createPermissionsQueryResponse = ({
    pushCode = false,
    forkProject = false,
    createMergeRequestIn = false,
  } = {}) => ({
    data: {
      project: {
        id: 1,
        __typename: '__typename',
        userPermissions: {
          __typename: '__typename',
          pushCode,
          forkProject,
          createMergeRequestIn,
        },
      },
    },
  });

  const factory = (currentPath, extraProps = {}, mockRoute = {}) => {
    const apolloProvider = createApolloProvider([[permissionsQuery, permissionsQuerySpy]]);

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectPathQuery,
      data: {
        projectPath: TEST_PROJECT_PATH,
      },
    });

    wrapper = shallowMount(Breadcrumbs, {
      apolloProvider,
      propsData: {
        currentPath,
        ...extraProps,
      },
      stubs: {
        RouterLink: RouterLinkStub,
        GlDisclosureDropdown,
      },
      mocks: {
        $route: {
          defaultMockRoute,
          ...mockRoute,
        },
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findNewDirectoryModal = () => wrapper.findComponent(NewDirectoryModal);
  const findRouterLink = () => wrapper.findAllComponents(RouterLinkStub);

  beforeEach(() => {
    permissionsQuerySpy = jest.fn().mockResolvedValue(createPermissionsQueryResponse());
  });

  it('queries for permissions', async () => {
    factory('/');

    // We need to wait for the projectPath query to resolve
    await waitForPromises();

    expect(permissionsQuerySpy).toHaveBeenCalledWith({
      projectPath: TEST_PROJECT_PATH,
    });
  });

  it.each`
    path                        | linkCount
    ${'/'}                      | ${1}
    ${'app'}                    | ${2}
    ${'app/assets'}             | ${3}
    ${'app/assets/javascripts'} | ${4}
  `('renders $linkCount links for path $path', ({ path, linkCount }) => {
    factory(path);

    expect(findRouterLink().length).toEqual(linkCount);
  });

  it.each`
    routeName            | path                        | linkTo
    ${'treePath'}        | ${'app/assets/javascripts'} | ${'/-/tree/app/assets/javascripts'}
    ${'treePathDecoded'} | ${'app/assets/javascripts'} | ${'/-/tree/app/assets/javascripts'}
    ${'blobPath'}        | ${'app/assets/index.js'}    | ${'/-/blob/app/assets/index.js'}
    ${'blobPathDecoded'} | ${'app/assets/index.js'}    | ${'/-/blob/app/assets/index.js'}
  `(
    'links to the correct router path when routeName is $routeName',
    ({ routeName, path, linkTo }) => {
      factory(path, {}, { name: routeName });
      expect(findRouterLink().at(3).props('to')).toEqual(linkTo);
    },
  );

  it('escapes hash in directory path', () => {
    factory('app/assets/javascripts#');

    expect(findRouterLink().at(3).props('to')).toEqual('/-/tree/app/assets/javascripts%23');
  });

  it('renders last link as active', () => {
    factory('app/assets');

    expect(findRouterLink().at(2).attributes('aria-current')).toEqual('page');
  });

  it('does not render add to tree dropdown when permissions are false', async () => {
    factory('/', { canCollaborate: false }, {});
    await nextTick();

    expect(findDropdown().exists()).toBe(false);
  });

  it.each`
    routeName            | isRendered
    ${'blobPath'}        | ${false}
    ${'blobPathDecoded'} | ${false}
    ${'treePath'}        | ${true}
    ${'treePathDecoded'} | ${true}
    ${'projectRoot'}     | ${true}
  `(
    'does render add to tree dropdown $isRendered when route is $routeName',
    ({ routeName, isRendered }) => {
      factory(
        'app/assets/javascripts.js',
        { canCollaborate: true, canEditTree: true },
        { name: routeName },
      );
      expect(findDropdown().exists()).toBe(isRendered);
    },
  );

  it('renders add to tree dropdown when permissions are true', async () => {
    permissionsQuerySpy.mockResolvedValue(
      createPermissionsQueryResponse({ forkProject: true, createMergeRequestIn: true }),
    );

    factory('/', { canCollaborate: true, canEditTree: true });
    await nextTick();

    expect(findDropdown().exists()).toBe(true);
  });

  describe('renders the upload blob modal', () => {
    beforeEach(() => {
      factory('/', { canEditTree: true });
    });

    it('does not render the modal while loading', () => {
      expect(findUploadBlobModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      await nextTick();

      expect(findUploadBlobModal().exists()).toBe(true);
    });
  });

  describe('renders the new directory modal', () => {
    beforeEach(() => {
      factory('some_dir', { canEditTree: true, newDirPath: 'root/master' });
    });
    it('does not render the modal while loading', () => {
      expect(findNewDirectoryModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      await nextTick();

      expect(findNewDirectoryModal().exists()).toBe(true);
      expect(findNewDirectoryModal().props('path')).toBe('root/master/some_dir');
    });
  });

  describe('"this repository" dropdown group', () => {
    it('renders when user has pushCode permissions', async () => {
      permissionsQuerySpy.mockResolvedValue(
        createPermissionsQueryResponse({
          pushCode: true,
        }),
      );

      factory('/', { canCollaborate: true });
      await waitForPromises();

      expect(findDropdownGroup().props('group').name).toBe(__('This repository'));
    });

    it('does not render when user does not have pushCode permissions', async () => {
      permissionsQuerySpy.mockResolvedValue(
        createPermissionsQueryResponse({
          pushCode: false,
        }),
      );

      factory('/', { canCollaborate: true });
      await waitForPromises();

      expect(findDropdownGroup().exists()).toBe(false);
    });
  });
});
