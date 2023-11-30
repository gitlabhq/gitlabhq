import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import CommitSection from '~/ci/pipeline_editor/components/commit/commit_section.vue';
import PipelineEditorDrawer from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';
import JobAssistantDrawer from '~/ci/pipeline_editor/components/job_assistant_drawer/job_assistant_drawer.vue';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorFileTree from '~/ci/pipeline_editor/components/file_tree/container.vue';
import PipelineEditorHeader from '~/ci/pipeline_editor/components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from '~/ci/pipeline_editor/components/pipeline_editor_tabs.vue';
import {
  CREATE_TAB,
  EDITOR_APP_DRAWER_HELP,
  EDITOR_APP_DRAWER_JOB_ASSISTANT,
  EDITOR_APP_DRAWER_NONE,
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

  const createComponent = ({ props = {}, glFeatures = {}, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineEditorHome, {
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

  const findCommitSection = () => wrapper.findComponent(CommitSection);
  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);
  const findModal = () => wrapper.findComponent(GlModal);
  const findPipelineEditorDrawer = () => wrapper.findComponent(PipelineEditorDrawer);
  const findJobAssistantDrawer = () => wrapper.findComponent(JobAssistantDrawer);
  const findPipelineEditorFileTree = () => wrapper.findComponent(PipelineEditorFileTree);
  const findPipelineEditorHeader = () => wrapper.findComponent(PipelineEditorHeader);
  const findPipelineEditorTabs = () => wrapper.findComponent(PipelineEditorTabs);
  const findPipelineEditorFileNav = () => wrapper.findComponent(PipelineEditorFileNav);

  const clickHelpBtn = async () => {
    await findPipelineEditorDrawer().vm.$emit('switch-drawer', EDITOR_APP_DRAWER_HELP);
  };
  const clickJobAssistantBtn = async () => {
    await findJobAssistantDrawer().vm.$emit('switch-drawer', EDITOR_APP_DRAWER_JOB_ASSISTANT);
  };
  const closeDrawer = async (finder) => {
    await finder().vm.$emit('switch-drawer', EDITOR_APP_DRAWER_NONE);
  };

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
      beforeEach(async () => {
        createComponent();
        await findFileNav().vm.$emit('select-branch');
      });

      it('is visible', () => {
        expect(findModal().exists()).toBe(true);
      });

      it('pass down `shouldLoadNewBranch` to the branch switcher when primary is selected', async () => {
        expect(findFileNav().props('shouldLoadNewBranch')).toBe(false);

        await findModal().vm.$emit('primary');

        expect(findFileNav().props('shouldLoadNewBranch')).toBe(true);
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

        await findPipelineEditorTabs().vm.$emit('set-current-tab', tab);

        expect(findCommitSection().isVisible()).toBe(shouldShow);
      },
    );

    it('shows the commit form again when coming back to the create tab', async () => {
      expect(findCommitSection().isVisible()).toBe(true);

      await findPipelineEditorTabs().vm.$emit('set-current-tab', MERGED_TAB);
      expect(findCommitSection().isVisible()).toBe(false);

      await findPipelineEditorTabs().vm.$emit('set-current-tab', CREATE_TAB);
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
    beforeEach(() => {
      createComponent();
    });

    it('hides the drawer by default', () => {
      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);
    });

    it('toggles the drawer on button click', async () => {
      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);

      await clickHelpBtn();
      expect(findPipelineEditorDrawer().props('isVisible')).toBe(true);

      await closeDrawer(findPipelineEditorDrawer);
      expect(findPipelineEditorDrawer().props('isVisible')).toBe(false);
    });
  });

  describe('job assistant drawer', () => {
    beforeEach(() => {
      createComponent({
        glFeatures: {
          ciJobAssistantDrawer: true,
        },
      });
    });

    it('hides the job assistant drawer by default', () => {
      expect(findJobAssistantDrawer().props('isVisible')).toBe(false);
    });

    it('toggles the job assistant drawer on button click', async () => {
      expect(findJobAssistantDrawer().props('isVisible')).toBe(false);

      await clickJobAssistantBtn();
      expect(findJobAssistantDrawer().props('isVisible')).toBe(true);

      await closeDrawer(findJobAssistantDrawer);
      expect(findJobAssistantDrawer().props('isVisible')).toBe(false);
    });

    it('covers helper drawer when opened last', async () => {
      await clickHelpBtn();
      await clickJobAssistantBtn();

      const jobAssistantIndex = Number(findJobAssistantDrawer().props().zIndex);
      const pipelineEditorDrawerIndex = Number(findPipelineEditorDrawer().props().zIndex);

      expect(jobAssistantIndex).toBeGreaterThan(pipelineEditorDrawerIndex);
    });

    it('covered by helper drawer when opened first', async () => {
      await clickJobAssistantBtn();
      await clickHelpBtn();

      const jobAssistantIndex = Number(findJobAssistantDrawer().props().zIndex);
      const pipelineEditorDrawerIndex = Number(findPipelineEditorDrawer().props().zIndex);

      expect(jobAssistantIndex).toBeLessThan(pipelineEditorDrawerIndex);
    });
  });

  describe('file tree', () => {
    const toggleFileTree = async () => {
      findPipelineEditorFileNav().vm.$emit('toggle-file-tree');
      await nextTick();
    };

    describe('file navigation', () => {
      beforeEach(() => {
        createComponent({});
      });

      it('toggles the drawer on `toggle-file-tree` event', async () => {
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
        createComponent();
      });

      it('shows the file tree by default', () => {
        expect(findPipelineEditorFileTree().exists()).toBe(true);
      });
    });

    describe('when file tree display state is not saved in local storage', () => {
      beforeEach(() => {
        createComponent();
      });

      it('hides the file tree by default', () => {
        expect(findPipelineEditorFileTree().exists()).toBe(false);
      });
    });
  });
});
