import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import BranchSwitcher from '~/pipeline_editor/components/file_nav/branch_switcher.vue';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import getAppStatus from '~/pipeline_editor/graphql/queries/client/app_status.query.graphql';
import { EDITOR_APP_STATUS_EMPTY, EDITOR_APP_STATUS_VALID } from '~/pipeline_editor/constants';

Vue.use(VueApollo);

describe('Pipeline editor file nav', () => {
  let wrapper;

  const mockApollo = createMockApollo();

  const createComponent = ({
    appStatus = EDITOR_APP_STATUS_VALID,
    isNewCiConfigFile = false,
    pipelineEditorFileTree = false,
  } = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getAppStatus,
      data: {
        app: {
          __typename: 'PipelineEditorApp',
          status: appStatus,
        },
      },
    });

    wrapper = extendedWrapper(
      shallowMount(PipelineEditorFileNav, {
        apolloProvider: mockApollo,
        provide: {
          glFeatures: {
            pipelineEditorFileTree,
          },
        },
        propsData: {
          isNewCiConfigFile,
        },
      }),
    );
  };

  const findBranchSwitcher = () => wrapper.findComponent(BranchSwitcher);
  const findFileTreeBtn = () => wrapper.findByTestId('file-tree-toggle');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the branch switcher', () => {
      expect(findBranchSwitcher().exists()).toBe(true);
    });

    it('does not render the file tree button', () => {
      expect(findFileTreeBtn().exists()).toBe(false);
    });
  });

  describe('with pipelineEditorFileTree feature flag ON', () => {
    describe('when editor is in the empty state', () => {
      it('does not render the file tree button', () => {
        createComponent({
          appStatus: EDITOR_APP_STATUS_EMPTY,
          isNewCiConfigFile: false,
          pipelineEditorFileTree: true,
        });

        expect(findFileTreeBtn().exists()).toBe(false);
      });
    });

    describe('when user is about to create their config file for the first time', () => {
      it('does not render the file tree button', () => {
        createComponent({
          appStatus: EDITOR_APP_STATUS_VALID,
          isNewCiConfigFile: true,
          pipelineEditorFileTree: true,
        });

        expect(findFileTreeBtn().exists()).toBe(false);
      });
    });

    describe('when editor has a non-empty config file open', () => {
      beforeEach(() => {
        createComponent({
          appStatus: EDITOR_APP_STATUS_VALID,
          isNewCiConfigFile: false,
          pipelineEditorFileTree: true,
        });
      });

      it('renders the file tree button', () => {
        expect(findFileTreeBtn().exists()).toBe(true);
        expect(findFileTreeBtn().props('icon')).toBe('file-tree');
      });

      it('file tree button emits toggle-file-tree event', () => {
        expect(wrapper.emitted('toggle-file-tree')).toBe(undefined);

        findFileTreeBtn().vm.$emit('click');

        expect(wrapper.emitted('toggle-file-tree')).toHaveLength(1);
      });
    });
  });
});
