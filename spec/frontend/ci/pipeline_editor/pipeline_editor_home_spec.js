import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlButton, GlDrawer, GlModal } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import CiEditorHeader from '~/ci/pipeline_editor/components/editor/ci_editor_header.vue';
import CommitSection from '~/ci/pipeline_editor/components/commit/commit_section.vue';
import PipelineEditorDrawer from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';
import JobAssistantDrawer from '~/ci/pipeline_editor/components/job_assistant_drawer/job_assistant_drawer.vue';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorFileTree from '~/ci/pipeline_editor/components/file_tree/container.vue';
import BranchSwitcher from '~/ci/pipeline_editor/components/file_nav/branch_switcher.vue';
import PipelineEditorHeader from '~/ci/pipeline_editor/components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from '~/ci/pipeline_editor/components/pipeline_editor_tabs.vue';
import {
  CREATE_TAB,
  FILE_TREE_DISPLAY_KEY,
  VALIDATE_TAB,
  MERGED_TAB,
  TABS_INDEX,
  VISUALIZE_TAB,
} from '~/ci/pipeline_editor/constants';
import PipelineEditorHome from '~/ci/pipeline_editor/pipeline_editor_home.vue';

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
          aiChatAvailable: false,
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
  const findJobAssistantDrawer = () => wrapper.findComponent(JobAssistantDrawer);
  const findPipelineEditorFileTree = () => wrapper.findComponent(PipelineEditorFileTree);
  const findPipelineEditorHeader = () => wrapper.findComponent(PipelineEditorHeader);
  const findPipelineEditorTabs = () => wrapper.findComponent(PipelineEditorTabs);
  const findFileTreeBtn = () => wrapper.findByTestId('file-tree-toggle');
  const findHelpBtn = () => wrapper.findByTestId('drawer-toggle');
  const findJobAssistantBtn = () => wrapper.findByTestId('job-assistant-drawer-toggle');

  afterEach(() => {
    localStorage.clear();
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
      ${VALIDATE_TAB}  | ${false}
      ${CREATE_TAB}    | ${true}
    `(
      'when the active tab is $tab the commit form is shown: $shouldShow',
      async ({ tab, shouldShow }) => {
        expect(findCommitSection().exists()).toBe(true);

        findPipelineEditorTabs().vm.$emit('set-current-tab', tab);

        await nextTick();

        expect(findCommitSection().isVisible()).toBe(shouldShow);
      },
    );

    it('shows the commit form again when coming back to the create tab', async () => {
      expect(findCommitSection().isVisible()).toBe(true);

      findPipelineEditorTabs().vm.$emit('set-current-tab', MERGED_TAB);
      await nextTick();
      expect(findCommitSection().isVisible()).toBe(false);

      findPipelineEditorTabs().vm.$emit('set-current-tab', CREATE_TAB);
      await nextTick();
      expect(findCommitSection().isVisible()).toBe(true);
    });

    describe('rendering with tab params', () => {
      it.each`
        tab              | shouldShow
        ${MERGED_TAB}    | ${false}
        ${VISUALIZE_TAB} | ${false}
        ${VALIDATE_TAB}  | ${false}
        ${CREATE_TAB}    | ${true}
      `(
        'when the tab query param is $tab the commit form is shown: $shouldShow',
        async ({ tab, shouldShow }) => {
          setWindowLocation(`https://gitlab.test/ci/editor/?tab=${TABS_INDEX[tab]}`);
          await createComponent({ stubs: { PipelineEditorTabs } });

          expect(findCommitSection().isVisible()).toBe(shouldShow);
        },
      );
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

      findPipelineEditorDrawer().findComponent(GlDrawer).vm.$emit('close');
      await nextTick();

      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);
    });
  });

  describe('job assistant drawer', () => {
    const clickHelpBtn = async () => {
      findHelpBtn().vm.$emit('click');
      await nextTick();
    };
    const clickJobAssistantBtn = async () => {
      findJobAssistantBtn().vm.$emit('click');
      await nextTick();
    };

    const stubs = {
      CiEditorHeader,
      GlButton,
      GlDrawer,
      PipelineEditorTabs,
      JobAssistantDrawer,
    };

    it('hides the job assistant drawer by default', () => {
      createComponent({
        glFeatures: {
          ciJobAssistantDrawer: true,
        },
      });

      expect(findJobAssistantDrawer().props('isVisible')).toBe(false);
    });

    it('toggles the job assistant drawer on button click', async () => {
      createComponent({
        stubs,
        glFeatures: {
          ciJobAssistantDrawer: true,
        },
      });

      await clickJobAssistantBtn();

      expect(findJobAssistantDrawer().props('isVisible')).toBe(true);

      await clickJobAssistantBtn();

      expect(findJobAssistantDrawer().props('isVisible')).toBe(false);
    });

    it("closes the job assistant drawer through the drawer's close button", async () => {
      createComponent({
        stubs,
        glFeatures: {
          ciJobAssistantDrawer: true,
        },
      });

      await clickJobAssistantBtn();

      expect(findJobAssistantDrawer().props('isVisible')).toBe(true);

      findJobAssistantDrawer().findComponent(GlDrawer).vm.$emit('close');
      await nextTick();

      expect(findJobAssistantDrawer().props('isVisible')).toBe(false);
    });

    it('covers helper drawer when opened last', async () => {
      createComponent({
        stubs: {
          ...stubs,
          PipelineEditorDrawer,
        },
        glFeatures: {
          ciJobAssistantDrawer: true,
        },
      });

      await clickHelpBtn();
      await clickJobAssistantBtn();

      const jobAssistantIndex = Number(findJobAssistantDrawer().props().zIndex);
      const pipelineEditorDrawerIndex = Number(findPipelineEditorDrawer().props().zIndex);

      expect(jobAssistantIndex).toBeGreaterThan(pipelineEditorDrawerIndex);
    });

    it('covered by helper drawer when opened first', async () => {
      createComponent({
        stubs: {
          ...stubs,
          PipelineEditorDrawer,
        },
        glFeatures: {
          ciJobAssistantDrawer: true,
        },
      });

      await clickJobAssistantBtn();
      await clickHelpBtn();

      const jobAssistantIndex = Number(findJobAssistantDrawer().props().zIndex);
      const pipelineEditorDrawerIndex = Number(findPipelineEditorDrawer().props().zIndex);

      expect(jobAssistantIndex).toBeLessThan(pipelineEditorDrawerIndex);
    });
  });

  describe('file tree', () => {
    const toggleFileTree = async () => {
      findFileTreeBtn().vm.$emit('click');
      await nextTick();
    };

    describe('button toggle', () => {
      beforeEach(() => {
        createComponent({
          stubs: {
            GlButton,
            PipelineEditorFileNav,
          },
        });
      });

      it('shows button toggle', () => {
        expect(findFileTreeBtn().exists()).toBe(true);
      });

      it('toggles the drawer on button click', async () => {
        await toggleFileTree();

        expect(findPipelineEditorFileTree().exists()).toBe(true);

        await toggleFileTree();

        expect(findPipelineEditorFileTree().exists()).toBe(false);
      });

      it('sets the display state in local storage', async () => {
        await toggleFileTree();

        expect(localStorage.getItem(FILE_TREE_DISPLAY_KEY)).toBe('true');

        await toggleFileTree();

        expect(localStorage.getItem(FILE_TREE_DISPLAY_KEY)).toBe('false');
      });
    });

    describe('when file tree display state is saved in local storage', () => {
      beforeEach(() => {
        localStorage.setItem(FILE_TREE_DISPLAY_KEY, 'true');
        createComponent({
          stubs: { PipelineEditorFileNav },
        });
      });

      it('shows the file tree by default', () => {
        expect(findPipelineEditorFileTree().exists()).toBe(true);
      });
    });

    describe('when file tree display state is not saved in local storage', () => {
      beforeEach(() => {
        createComponent({
          stubs: { PipelineEditorFileNav },
        });
      });

      it('hides the file tree by default', () => {
        expect(findPipelineEditorFileTree().exists()).toBe(false);
      });
    });
  });
});
