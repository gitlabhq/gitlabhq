import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlButton, GlDrawer, GlModal } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CiEditorHeader from '~/pipeline_editor/components/editor/ci_editor_header.vue';
import CommitSection from '~/pipeline_editor/components/commit/commit_section.vue';
import PipelineEditorDrawer from '~/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import BranchSwitcher from '~/pipeline_editor/components/file_nav/branch_switcher.vue';
import PipelineEditorHeader from '~/pipeline_editor/components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import { MERGED_TAB, VISUALIZE_TAB, CREATE_TAB, LINT_TAB } from '~/pipeline_editor/constants';
import PipelineEditorHome from '~/pipeline_editor/pipeline_editor_home.vue';

import { mockLintResponse, mockCiYml } from './mock_data';

jest.mock('~/lib/utils/common_utils');

describe('Pipeline editor home wrapper', () => {
  let wrapper;

  const createComponent = ({ props = {}, glFeatures = {}, data = {}, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineEditorHome, {
        data: () => data,
        propsData: {
          ciConfigData: mockLintResponse,
          ciFileContent: mockCiYml,
          isCiConfigDataLoading: false,
          isNewCiConfigFile: false,
          ...props,
        },
        provide: {
          projectFullPath: '',
          totalBranches: 19,
          glFeatures: {
            ...glFeatures,
          },
        },
        stubs,
      }),
    );
  };

  const findBranchSwitcher = () => wrapper.findComponent(BranchSwitcher);
  const findCommitSection = () => wrapper.findComponent(CommitSection);
  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);
  const findModal = () => wrapper.findComponent(GlModal);
  const findPipelineEditorDrawer = () => wrapper.findComponent(PipelineEditorDrawer);
  const findPipelineEditorHeader = () => wrapper.findComponent(PipelineEditorHeader);
  const findPipelineEditorTabs = () => wrapper.findComponent(PipelineEditorTabs);
  const findHelpBtn = () => wrapper.findByTestId('drawer-toggle');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the file nav', () => {
      expect(findFileNav().exists()).toBe(true);
    });

    it('shows the pipeline editor header', () => {
      expect(findPipelineEditorHeader().exists()).toBe(true);
    });

    it('shows the pipeline editor tabs', () => {
      expect(findPipelineEditorTabs().exists()).toBe(true);
    });

    it('shows the commit section by default', () => {
      expect(findCommitSection().exists()).toBe(true);
    });
  });

  describe('modal when switching branch', () => {
    describe('when `showSwitchBranchModal` value is false', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is not visible', () => {
        expect(findModal().exists()).toBe(false);
      });
    });
    describe('when `showSwitchBranchModal` value is true', () => {
      beforeEach(() => {
        createComponent({
          data: { showSwitchBranchModal: true },
          stubs: { PipelineEditorFileNav },
        });
      });

      it('is visible', () => {
        expect(findModal().exists()).toBe(true);
      });

      it('pass down `shouldLoadNewBranch` to the branch switcher when primary is selected', async () => {
        expect(findBranchSwitcher().props('shouldLoadNewBranch')).toBe(false);

        await findModal().vm.$emit('primary');

        expect(findBranchSwitcher().props('shouldLoadNewBranch')).toBe(true);
      });

      it('closes the modal when secondary action is selected', async () => {
        expect(findModal().exists()).toBe(true);

        await findModal().vm.$emit('secondary');

        expect(findModal().exists()).toBe(false);
      });
    });
  });

  describe('commit form toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      tab              | shouldShow
      ${MERGED_TAB}    | ${false}
      ${VISUALIZE_TAB} | ${false}
      ${LINT_TAB}      | ${false}
      ${CREATE_TAB}    | ${true}
    `(
      'when the active tab is $tab the commit form is shown: $shouldShow',
      async ({ tab, shouldShow }) => {
        expect(findCommitSection().exists()).toBe(true);

        findPipelineEditorTabs().vm.$emit('set-current-tab', tab);

        await nextTick();

        expect(findCommitSection().exists()).toBe(shouldShow);
      },
    );

    it('shows the commit form again when coming back to the create tab', async () => {
      expect(findCommitSection().exists()).toBe(true);

      findPipelineEditorTabs().vm.$emit('set-current-tab', MERGED_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(false);

      findPipelineEditorTabs().vm.$emit('set-current-tab', CREATE_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(true);
    });
  });

  describe('WalkthroughPopover events', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when "walkthrough-popover-cta-clicked" is emitted from pipeline editor tabs', () => {
      it('passes down `scrollToCommitForm=true` to commit section', async () => {
        expect(findCommitSection().props('scrollToCommitForm')).toBe(false);
        await findPipelineEditorTabs().vm.$emit('walkthrough-popover-cta-clicked');
        expect(findCommitSection().props('scrollToCommitForm')).toBe(true);
      });
    });

    describe('when "scrolled-to-commit-form" is emitted from commit section', () => {
      it('passes down `scrollToCommitForm=false` to commit section', async () => {
        await findPipelineEditorTabs().vm.$emit('walkthrough-popover-cta-clicked');
        expect(findCommitSection().props('scrollToCommitForm')).toBe(true);
        await findCommitSection().vm.$emit('scrolled-to-commit-form');
        expect(findCommitSection().props('scrollToCommitForm')).toBe(false);
      });
    });
  });

  describe('help drawer', () => {
    const clickHelpBtn = async () => {
      findHelpBtn().vm.$emit('click');
      await nextTick();
    };

    it('hides the drawer by default', () => {
      createComponent();

      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);
    });

    it('toggles the drawer on button click', async () => {
      createComponent({
        stubs: {
          CiEditorHeader,
          GlButton,
          GlDrawer,
          PipelineEditorTabs,
          PipelineEditorDrawer,
        },
      });

      await clickHelpBtn();

      expect(findPipelineEditorDrawer().props('isVisible')).toBe(true);

      await clickHelpBtn();

      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);
    });

    it("closes the drawer through the drawer's close button", async () => {
      createComponent({
        stubs: {
          CiEditorHeader,
          GlButton,
          GlDrawer,
          PipelineEditorTabs,
          PipelineEditorDrawer,
        },
      });

      await clickHelpBtn();

      expect(findPipelineEditorDrawer().props('isVisible')).toBe(true);

      findPipelineEditorDrawer().find(GlDrawer).vm.$emit('close');
      await nextTick();

      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);
    });
  });
});
