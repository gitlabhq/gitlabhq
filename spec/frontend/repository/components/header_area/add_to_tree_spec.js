import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AddToTree from '~/repository/components/header_area/add_to_tree.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';

import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';

import createApolloProvider from 'helpers/mock_apollo_helper';

const TEST_PROJECT_PATH = 'test-project/path';

Vue.use(VueApollo);

jest.mock('lodash/uniqueId', () => () => 'fake-id');

describe('Add to tree dropdown and modal components', () => {
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

  const factory = ({ currentPath, extraProps = {}, mockRoute = {} } = {}) => {
    const apolloProvider = createApolloProvider([[permissionsQuery, permissionsQuerySpy]]);

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectPathQuery,
      data: {
        projectPath: TEST_PROJECT_PATH,
      },
    });

    wrapper = shallowMount(AddToTree, {
      apolloProvider,
      provide: {
        projectRootPath: TEST_PROJECT_PATH,
      },
      propsData: {
        currentPath,
        ...extraProps,
      },
      stubs: {
        GlDisclosureDropdown,
      },
      mocks: {
        $route: {
          name: 'treePath',
          ...mockRoute,
        },
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findNewDirectoryModal = () => wrapper.findComponent(NewDirectoryModal);

  beforeEach(() => {
    permissionsQuerySpy = jest.fn().mockResolvedValue(createPermissionsQueryResponse());
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

    it('renders the modal with correct props once loaded', async () => {
      await waitForPromises();

      expect(findUploadBlobModal().exists()).toBe(true);
      expect(findUploadBlobModal().props()).toStrictEqual({
        canPushCode: false,
        canPushToBranch: false,
        commitMessage: 'Upload New File',
        emptyRepo: false,
        modalId: 'fake-id',
        originalBranch: '',
        path: '',
        replacePath: null,
        targetBranch: '',
        uploadPath: null,
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
});
