import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import BranchSwitcher from '~/ci/pipeline_editor/components/file_nav/branch_switcher.vue';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import FileTreePopover from '~/ci/pipeline_editor/components/popovers/file_tree_popover.vue';
import getAppStatus from '~/ci/pipeline_editor/graphql/queries/client/app_status.query.graphql';
import {
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
} from '~/ci/pipeline_editor/constants';

Vue.use(VueApollo);

describe('Pipeline editor file nav', () => {
  let wrapper;

  const mockApollo = createMockApollo();

  const createComponent = ({
    appStatus = EDITOR_APP_STATUS_VALID,
    isNewCiConfigFile = false,
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
        propsData: {
          isNewCiConfigFile,
        },
      }),
    );
  };

  const findBranchSwitcher = () => wrapper.findComponent(BranchSwitcher);
  const findFileTreeBtn = () => wrapper.findByTestId('file-tree-toggle');
  const findPopoverContainer = () => wrapper.findComponent(FileTreePopover);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the branch switcher', () => {
      expect(findBranchSwitcher().exists()).toBe(true);
    });
  });

  describe('file tree', () => {
    describe('when editor is in the empty state', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_EMPTY, isNewCiConfigFile: false });
      });

      it('does not render the file tree button', () => {
        expect(findFileTreeBtn().exists()).toBe(false);
      });

      it('does not render the file tree popover', () => {
        expect(findPopoverContainer().exists()).toBe(false);
      });
    });

    describe('when user is about to create their config file for the first time', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_VALID, isNewCiConfigFile: true });
      });

      it('does not render the file tree button', () => {
        expect(findFileTreeBtn().exists()).toBe(false);
      });

      it('does not render the file tree popover', () => {
        expect(findPopoverContainer().exists()).toBe(false);
      });
    });

    describe('when app is in a global loading state', () => {
      it('renders the file tree button with a loading icon', () => {
        createComponent({ appStatus: EDITOR_APP_STATUS_LOADING, isNewCiConfigFile: false });

        expect(findFileTreeBtn().exists()).toBe(true);
        expect(findFileTreeBtn().attributes('loading')).toBe('true');
      });
    });

    describe('when editor has a non-empty config file open', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_VALID, isNewCiConfigFile: false });
      });

      it('renders the file tree button', () => {
        expect(findFileTreeBtn().exists()).toBe(true);
        expect(findFileTreeBtn().props('icon')).toBe('file-tree');
      });

      it('renders the file tree popover', () => {
        expect(findPopoverContainer().exists()).toBe(true);
      });

      it('file tree button emits toggle-file-tree event', () => {
        expect(wrapper.emitted('toggle-file-tree')).toBe(undefined);

        findFileTreeBtn().vm.$emit('click');

        expect(wrapper.emitted('toggle-file-tree')).toHaveLength(1);
      });
    });
  });
});
