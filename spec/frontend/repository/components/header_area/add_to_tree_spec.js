import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AddToTree from '~/repository/components/header_area/add_to_tree.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';

import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';

import createApolloProvider from 'helpers/mock_apollo_helper';
import * as urlUtils from '~/lib/utils/url_utility';

import {
  ADD_DROPDOWN_CLICK,
  NEW_FILE_CLICK,
  UPLOAD_FILE_CLICK,
  NEW_DIRECTORY_CLICK,
  NEW_BRANCH_CLICK,
  NEW_TAG_CLICK,
} from '~/repository/components/header_area/constants';

const TEST_PROJECT_PATH = 'test-project/path';

Vue.use(VueApollo);

jest.mock('~/tracking', () => ({
  InternalEvents: {
    mixin: () => ({
      methods: {
        trackEvent: jest.fn(),
      },
    }),
  },
}));

describe('Add to tree dropdown and modal components', () => {
  let wrapper;
  let permissionsQuerySpy;
  let trackingSpy;
  let visitUrlSpy;

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

    wrapper = mount(AddToTree, {
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
      mixins: [
        {
          methods: {
            trackEvent: trackingSpy,
          },
        },
      ],
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findNewDirectoryModal = () => wrapper.findComponent(NewDirectoryModal);

  beforeEach(() => {
    permissionsQuerySpy = jest.fn().mockResolvedValue(createPermissionsQueryResponse());
    trackingSpy = jest.fn();
    visitUrlSpy = jest.spyOn(urlUtils, 'visitUrl').mockImplementation(() => {});
  });

  afterEach(() => {
    wrapper?.destroy();
    jest.resetAllMocks();
  });

  describe('permissions-based rendering', () => {
    beforeEach(async () => {
      permissionsQuerySpy.mockResolvedValue(
        createPermissionsQueryResponse({ forkProject: true, createMergeRequestIn: true }),
      );

      factory({
        currentPath: '/',
        extraProps: {
          canCollaborate: true,
          canEditTree: true,
          newBlobPath: '/some/new/blob/path',
        },
      });

      await waitForPromises();
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

    it('renders add to tree dropdown when permissions are true', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('tracks clicking event when dropdown is shown', async () => {
      await findDropdown().vm.$emit('shown');

      expect(trackingSpy).toHaveBeenCalledWith(ADD_DROPDOWN_CLICK);
    });

    it('tracks new file click event', async () => {
      await findDropdown().vm.$emit('shown');
      await wrapper.find('[data-testid="new-file-menu-item"]').trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(NEW_FILE_CLICK);
      expect(visitUrlSpy).toHaveBeenCalled();
    });
  });

  describe('upload blob modal', () => {
    beforeEach(() => {
      factory({
        currentPath: '/',
        extraProps: {
          canCollaborate: true,
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
        modalId: expect.stringMatching(/^modal-upload-blob.*/),
        originalBranch: '',
        path: '',
        replacePath: null,
        targetBranch: '',
        uploadPath: null,
      });
    });

    it('tracks clicking event when uploading a file', async () => {
      await waitForPromises();

      await findDropdown().vm.$emit('shown');
      await wrapper.find('[data-testid="upload-file-menu-item"]').trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(UPLOAD_FILE_CLICK);
    });
  });

  describe('new directory modal', () => {
    beforeEach(() => {
      factory({
        currentPath: 'some_dir',
        extraProps: {
          canCollaborate: true,
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

    it('tracks clicking event when creating a new directory', async () => {
      await waitForPromises();

      await findDropdown().vm.$emit('shown');
      await wrapper.find('[data-testid="new-directory-menu-item"]').trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(NEW_DIRECTORY_CLICK);
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

    describe('tracks repository actions', () => {
      beforeEach(async () => {
        permissionsQuerySpy.mockResolvedValue(createPermissionsQueryResponse({ pushCode: true }));

        factory({
          currentPath: '/',
          extraProps: {
            canCollaborate: true,
            canEditTree: true,
            newBranchPath: '/',
            newTagPath: '/',
          },
        });

        await waitForPromises();
      });

      it('tracks clicking event when creating a new branch', async () => {
        await findDropdown().vm.$emit('shown');
        await wrapper.find('[data-testid="new-branch-menu-item"]').trigger('click');

        expect(trackingSpy).toHaveBeenCalledWith(NEW_BRANCH_CLICK);
        expect(visitUrlSpy).toHaveBeenCalled();
      });

      it('tracks clicking event when creating a new tag', async () => {
        await findDropdown().vm.$emit('shown');
        await wrapper.find('[data-testid="new-tag-menu-item"]').trigger('click');

        expect(trackingSpy).toHaveBeenCalledWith(NEW_TAG_CLICK);
        expect(visitUrlSpy).toHaveBeenCalled();
      });
    });
  });
});
