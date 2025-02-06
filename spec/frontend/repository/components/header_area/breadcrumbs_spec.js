import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlDisclosureDropdownGroup, GlLink } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';

import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';

import createApolloProvider from 'helpers/mock_apollo_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

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

  const factory = ({
    currentPath,
    extraProps = {},
    mockRoute = {},
    glFeatures = { blobOverflowMenu: false },
  } = {}) => {
    const apolloProvider = createApolloProvider([[permissionsQuery, permissionsQuerySpy]]);

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectPathQuery,
      data: {
        projectPath: TEST_PROJECT_PATH,
      },
    });

    wrapper = shallowMount(Breadcrumbs, {
      apolloProvider,
      provide: {
        projectRootPath: TEST_PROJECT_PATH,
        isBlobView: extraProps.isBlobView,
        glFeatures,
      },
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
  const findRouterLinks = () => wrapper.findAllComponents(GlLink);

  beforeEach(() => {
    permissionsQuerySpy = jest.fn().mockResolvedValue(createPermissionsQueryResponse());
  });

  it('queries for permissions', async () => {
    factory({ currentPath: '/' });

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
    factory({ currentPath: path });

    expect(findRouterLinks().length).toEqual(linkCount);
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
      factory({
        currentPath: path,
        mockRoute: {
          name: routeName,
        },
      });
      expect(findRouterLinks().at(3).attributes('to')).toEqual(linkTo);
    },
  );

  it('escapes hash in directory path', () => {
    factory({ currentPath: 'app/assets/javascripts#' });

    expect(findRouterLinks().at(3).attributes('to')).toEqual('/-/tree/app/assets/javascripts%23');
  });

  it('renders last link as active', () => {
    factory({ currentPath: 'app/assets' });

    expect(findRouterLinks().at(2).attributes('aria-current')).toEqual('page');
  });

  it('does not render add to tree dropdown when permissions are false', async () => {
    factory({
      currentPath: '/',
      extraProps: {
        canCollaborate: false,
      },
    });
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
      factory({
        currentPath: 'app/assets/javascripts.js',
        extraProps: {
          canCollaborate: true,
          canEditTree: true,
        },
        mockRoute: {
          name: routeName,
        },
      });
      expect(findDropdown().exists()).toBe(isRendered);
    },
  );

  it.each`
    currentPath           | expectedPath | routeName
    ${'foo'}              | ${'foo'}     | ${'treePath'}
    ${'foo/bar'}          | ${'foo/bar'} | ${'treePath'}
    ${'foo/bar/index.js'} | ${'foo/bar'} | ${'blobPath'}
  `(
    'sets data-current-path to $expectedPath when path is $currentPath and routeName is $routeName',
    ({ currentPath, expectedPath, routeName }) => {
      factory({
        currentPath,
        mockRoute: {
          name: routeName,
        },
      });

      expect(wrapper.attributes('data-current-path')).toBe(expectedPath);
    },
  );

  it('renders add to tree dropdown when permissions are true', async () => {
    permissionsQuerySpy.mockResolvedValue(
      createPermissionsQueryResponse({ forkProject: true, createMergeRequestIn: true }),
    );

    factory({
      currentPath: '/',
      extraProps: {
        canCollaborate: true,
        canEditTree: true,
      },
    });
    await nextTick();

    expect(findDropdown().exists()).toBe(true);
  });

  describe('copy-to-clipboard icon button', () => {
    it.each`
      description                                  | flagValue | currentPath        | expected
      ${'does not render button '}                 | ${false}  | ${'/path/to/file'} | ${false}
      ${'does not render button '}                 | ${true}   | ${''}              | ${false}
      ${'renders button that copies current path'} | ${true}   | ${'/path/to/file'} | ${true}
    `(
      'when flag is $flagValue and currentPath is "$currentPath", $description',
      ({ flagValue, currentPath, expected }) => {
        factory({
          currentPath,
          glFeatures: {
            blobOverflowMenu: flagValue,
          },
        });
        const btn = wrapper.findComponent(ClipboardButton);
        expect(btn.exists()).toBe(expected);
        if (expected) {
          expect(btn.vm.text).toBe(currentPath);
        }
      },
    );
  });

  describe('renders the upload blob modal', () => {
    beforeEach(() => {
      factory({
        currentPath: '/',
        extraProps: {
          canEditTree: true,
        },
      });
    });

    it('does not render the modal while loading', () => {
      expect(findUploadBlobModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      await waitForPromises();

      expect(findUploadBlobModal().exists()).toBe(true);
      expect(findUploadBlobModal().props()).toStrictEqual({
        canPushCode: false,
        canPushToBranch: false,
        commitMessage: 'Upload New File',
        emptyRepo: false,
        modalId: 'modal-upload-blob',
        originalBranch: '',
        path: '',
        replacePath: null,
        targetBranch: '',
      });
    });
  });

  describe('renders the new directory modal', () => {
    beforeEach(() => {
      factory({
        currentPath: 'some_dir',
        extraProps: {
          canEditTree: true,
          newDirPath: 'root/master',
        },
      });
    });
    it('does not render the modal while loading', () => {
      expect(findNewDirectoryModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      await waitForPromises();

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

      factory({
        currentPath: '/',
        extraProps: {
          canCollaborate: true,
        },
      });
      await waitForPromises();

      expect(findDropdownGroup().props('group').name).toBe('This repository');
    });

    it('does not render when user does not have pushCode permissions', async () => {
      permissionsQuerySpy.mockResolvedValue(
        createPermissionsQueryResponse({
          pushCode: false,
        }),
      );

      factory({
        currentPath: '/',
        extraProps: {
          canCollaborate: true,
        },
      });
      await waitForPromises();

      expect(findDropdownGroup().exists()).toBe(false);
    });
  });

  describe('link rendering', () => {
    it('passes `href` to GlLink when isBlobView is true', () => {
      factory({
        currentPath: '/',
        extraProps: {
          isBlobView: true,
        },
      });

      expect(findRouterLinks().at(0).attributes('href')).toBe('/test-project/path/-/tree');
    });

    it('passes `to` to GlLink when isBlobView is false', () => {
      factory({
        currentPath: '/',
        extraProps: {
          isBlobView: false,
        },
      });

      expect(findRouterLinks().at(0).attributes('to')).toBe('/-/tree');
    });
  });
});
