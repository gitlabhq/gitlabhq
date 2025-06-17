import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import projectInfoQuery from 'ee_else_ce/repository/queries/project_info.query.graphql';
import BlobOverflowMenu from '~/repository/components/header_area/blob_overflow_menu.vue';
import BlobDefaultActionsGroup from '~/repository/components/header_area/blob_default_actions_group.vue';
import BlobRepositoryActionsGroup from '~/repository/components/header_area/blob_repository_actions_group.vue';
import BlobButtonGroup from 'ee_else_ce/repository/components/header_area/blob_button_group.vue';
import BlobDeleteFileGroup from '~/repository/components/header_area/blob_delete_file_group.vue';
import createRouter from '~/repository/router';
import { projectMock, blobControlsDataMock, refMock } from 'ee_else_ce_jest/repository/mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils', () => ({
  isLoggedIn: jest.fn().mockReturnValue(true),
}));

describe('Blob Overflow Menu', () => {
  let router;
  let wrapper;
  let fakeApollo;

  const projectPath = '/some/project';

  const projectInfoQuerySuccessResolver = jest
    .fn()
    .mockResolvedValue({ data: { project: projectMock } });
  const projectInfoQueryErrorResolver = jest.fn().mockRejectedValue(new Error('Request failed'));

  const createComponent = async ({
    propsData = {},
    projectInfoResolver = projectInfoQuerySuccessResolver,
    provide = {},
    routerOverride = {},
  } = {}) => {
    fakeApollo = createMockApollo([[projectInfoQuery, projectInfoResolver]]);
    router = createRouter(projectPath, refMock);

    await router.push({
      name: 'blobPathDecoded',
      params: { path: '/some/file.js' },
      ...routerOverride,
    });

    wrapper = shallowMountExtended(BlobOverflowMenu, {
      router,
      apolloProvider: fakeApollo,
      provide: {
        blobInfo: blobControlsDataMock.repository.blobs.nodes[0],
        currentRef: refMock,
        rootRef: 'main',
        glFeatures: {
          fileLocks: false,
        },
        ...provide,
      },
      propsData: {
        projectPath,
        userPermissions: blobControlsDataMock.userPermissions,
        ...propsData,
      },
      stub: {
        GlDisclosureDropdown,
      },
    });
    await waitForPromises();
  };

  const findBlobActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findBlobDefaultActionsGroup = () => wrapper.findComponent(BlobDefaultActionsGroup);
  const findBlobButtonGroup = () => wrapper.findComponent(BlobButtonGroup);
  const findBlobRepositoryActionsGroup = () => wrapper.findComponent(BlobRepositoryActionsGroup);
  const findBlobDeleteFileGroup = () => wrapper.findComponent(BlobDeleteFileGroup);

  beforeEach(async () => {
    createAlert.mockClear();
    await createComponent();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  it('renders blob actions dropdown', () => {
    expect(findBlobActionsDropdown().exists()).toBe(true);
    expect(findBlobActionsDropdown().props('toggleText')).toBe('File actions');
  });

  it('creates an alert with the correct message, when projectInfo query fails', async () => {
    await createComponent({ projectInfoResolver: projectInfoQueryErrorResolver });

    expect(createAlert).toHaveBeenCalledWith({
      message: 'An error occurred while fetching lock information, please try again.',
    });
  });

  describe('active viewer based on plain attribute and blob.richViewer', () => {
    const { richViewer } = blobControlsDataMock.repository.blobs.nodes[0];

    it.each`
      plain  | richViewerValue | activeViewerType
      ${'0'} | ${richViewer}   | ${RICH_BLOB_VIEWER}
      ${'1'} | ${richViewer}   | ${SIMPLE_BLOB_VIEWER}
      ${'0'} | ${null}         | ${SIMPLE_BLOB_VIEWER}
      ${'1'} | ${null}         | ${SIMPLE_BLOB_VIEWER}
    `(
      'activeViewerType is `$activeViewerType` when plain is $plain and richViewer is $richViewerValue',
      async ({ plain, richViewerValue, activeViewerType }) => {
        await createComponent({
          provide: {
            blobInfo: {
              ...blobControlsDataMock.repository.blobs.nodes[0],
              richViewer: richViewerValue,
            },
          },
        });

        await router.replace({ query: { plain } });
        await nextTick();

        expect(findBlobDefaultActionsGroup().props('activeViewerType')).toBe(activeViewerType);
      },
    );
  });

  describe('Default blob actions', () => {
    it('renders BlobDefaultActionsGroup component', () => {
      expect(findBlobDefaultActionsGroup().exists()).toBe(true);
    });

    describe('events', () => {
      it('proxy copy event when overrideCopy is true', async () => {
        await createComponent({
          propsData: {
            overrideCopy: true,
          },
        });

        findBlobDefaultActionsGroup().vm.$emit('copy');
        expect(wrapper.emitted('copy')).toHaveLength(1);
      });

      it('does not proxy copy event when overrideCopy is false', () => {
        createComponent({
          propsData: {
            overrideCopy: false,
          },
        });

        findBlobDefaultActionsGroup().vm.$emit('copy');
        expect(wrapper.emitted('copy')).toBeUndefined();
      });

      it('proxy showForkSuggestion event from BlobButtonGRoup', () => {
        findBlobButtonGroup().vm.$emit('showForkSuggestion');
        expect(wrapper.emitted('showForkSuggestion')).toHaveLength(1);
      });

      it('proxy showForkSuggestion event from BlobDeleteFileGRoup', () => {
        findBlobDeleteFileGroup().vm.$emit('showForkSuggestion');
        expect(wrapper.emitted('showForkSuggestion')).toHaveLength(1);
      });
    });
  });

  describe('Blob Button Group', () => {
    it('renders component', () => {
      expect(findBlobButtonGroup().exists()).toBe(true);
    });

    it('does not render when blob is archived', async () => {
      await createComponent({
        provide: {
          blobInfo: {
            ...blobControlsDataMock.repository.blobs.nodes[0],
            archived: true,
          },
        },
      });

      expect(findBlobButtonGroup().exists()).toBe(false);
    });

    it('does not render when user is not logged in', async () => {
      isLoggedIn.mockImplementationOnce(() => false);
      await createComponent();

      expect(findBlobButtonGroup().exists()).toBe(false);
    });
  });

  describe('Blob Delete File Group', () => {
    it('renders when blob is not archived, and user is logged in', () => {
      expect(findBlobDeleteFileGroup().exists()).toBe(true);
    });

    it('does not render when blob is archived', async () => {
      await createComponent({
        provide: {
          blobInfo: {
            ...blobControlsDataMock.repository.blobs.nodes[0],
            archived: true,
          },
        },
      });

      expect(findBlobDeleteFileGroup().exists()).toBe(false);
    });

    it('does not render when user is not logged in', async () => {
      isLoggedIn.mockImplementationOnce(() => false);
      await createComponent();

      expect(findBlobDeleteFileGroup().exists()).toBe(false);
    });
  });

  describe('Blob Repository Actions Group', () => {
    it('renders component', () => {
      expect(findBlobRepositoryActionsGroup().exists()).toBe(true);
    });
  });
});
