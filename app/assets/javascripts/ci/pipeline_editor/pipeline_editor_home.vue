<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import JobAssistantDrawer from 'jh_else_ce/ci/pipeline_editor/components/job_assistant_drawer/job_assistant_drawer.vue';
import CommitSection from './components/commit/commit_section.vue';
import PipelineEditorDrawer from './components/drawer/pipeline_editor_drawer.vue';
import PipelineEditorFileNav from './components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorFileTree from './components/file_tree/container.vue';
import PipelineEditorHeader from './components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from './components/pipeline_editor_tabs.vue';
import {
  CREATE_TAB,
  FILE_TREE_DISPLAY_KEY,
  EDITOR_APP_DRAWER_HELP,
  EDITOR_APP_DRAWER_JOB_ASSISTANT,
  EDITOR_APP_DRAWER_AI_ASSISTANT,
  EDITOR_APP_DRAWER_NONE,
} from './constants';

export default {
  EDITOR_APP_DRAWER_HELP,
  EDITOR_APP_DRAWER_JOB_ASSISTANT,
  EDITOR_APP_DRAWER_AI_ASSISTANT,
  commitSectionRef: 'commitSectionRef',
  modal: {
    switchBranch: {
      title: __('You have unsaved changes'),
      body: __('Uncommitted changes will be lost if you change branches. Do you want to continue?'),
      actionPrimary: {
        text: __('Switch Branches'),
      },
      actionSecondary: {
        text: __('Cancel'),
        attributes: { variant: 'default' },
      },
    },
  },
  components: {
    CommitSection,
    GlModal,
    PipelineEditorDrawer,
    JobAssistantDrawer,
    PipelineEditorFileNav,
    PipelineEditorFileTree,
    PipelineEditorHeader,
    PipelineEditorTabs,
  },
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    ciFileContent: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
    hasUnsavedChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      currentDrawer: EDITOR_APP_DRAWER_NONE,
      currentTab: CREATE_TAB,
      scrollToCommitForm: false,
      shouldLoadNewBranch: false,
      currentDrawerIndex: DRAWER_Z_INDEX,
      drawerIndex: {
        [EDITOR_APP_DRAWER_HELP]: DRAWER_Z_INDEX,
        [EDITOR_APP_DRAWER_JOB_ASSISTANT]: DRAWER_Z_INDEX,
        [EDITOR_APP_DRAWER_AI_ASSISTANT]: DRAWER_Z_INDEX,
      },
      showFileTree: false,
      showSwitchBranchModal: false,
    };
  },
  computed: {
    showCommitForm() {
      return this.currentTab === CREATE_TAB;
    },
    includesFiles() {
      return this.ciConfigData?.includes || [];
    },
    showHelpDrawer() {
      return this.currentDrawer === EDITOR_APP_DRAWER_HELP;
    },
    showJobAssistantDrawer() {
      return this.currentDrawer === EDITOR_APP_DRAWER_JOB_ASSISTANT;
    },
  },
  mounted() {
    this.showFileTree = JSON.parse(localStorage.getItem(FILE_TREE_DISPLAY_KEY)) || false;
  },
  methods: {
    closeBranchModal() {
      this.showSwitchBranchModal = false;
    },
    handleConfirmSwitchBranch() {
      this.showSwitchBranchModal = true;
    },
    switchDrawer(drawerName) {
      this.currentDrawer = drawerName;
      if (this.drawerIndex[drawerName]) {
        this.currentDrawerIndex += 1;
        this.drawerIndex[drawerName] = this.currentDrawerIndex;
      }
    },
    toggleFileTree() {
      this.showFileTree = !this.showFileTree;
      localStorage.setItem(FILE_TREE_DISPLAY_KEY, this.showFileTree);
    },
    switchBranch() {
      this.showSwitchBranchModal = false;
      this.shouldLoadNewBranch = true;
    },
    setCurrentTab(tabName) {
      this.currentTab = tabName;
    },
    setScrollToCommitForm(newValue = true) {
      this.scrollToCommitForm = newValue;
    },
  },
};
</script>

<template>
  <div class="gl-w-full gl-transition-all">
    <gl-modal
      v-if="showSwitchBranchModal"
      visible
      modal-id="switchBranchModal"
      :title="$options.modal.switchBranch.title"
      :action-primary="$options.modal.switchBranch.actionPrimary"
      :action-secondary="$options.modal.switchBranch.actionSecondary"
      @primary="switchBranch"
      @secondary="closeBranchModal"
      @cancel="closeBranchModal"
      @hide="closeBranchModal"
    >
      {{ $options.modal.switchBranch.body }}
    </gl-modal>
    <pipeline-editor-file-nav
      :has-unsaved-changes="hasUnsavedChanges"
      :is-new-ci-config-file="isNewCiConfigFile"
      :should-load-new-branch="shouldLoadNewBranch"
      @select-branch="handleConfirmSwitchBranch"
      @toggle-file-tree="toggleFileTree"
      v-on="$listeners"
    />
    <div class="gl-flex gl-w-full gl-flex-col md:gl-flex-row">
      <pipeline-editor-file-tree
        v-if="showFileTree"
        class="gl-shrink-0"
        :includes="includesFiles"
      />
      <div class="gl-min-w-0 gl-grow">
        <pipeline-editor-header
          :ci-config-data="ciConfigData"
          :commit-sha="commitSha"
          :is-new-ci-config-file="isNewCiConfigFile"
          v-on="$listeners"
        />
        <pipeline-editor-tabs
          :ci-config-data="ciConfigData"
          :ci-file-content="ciFileContent"
          :commit-sha="commitSha"
          :current-tab="currentTab"
          :is-new-ci-config-file="isNewCiConfigFile"
          :show-help-drawer="showHelpDrawer"
          :show-job-assistant-drawer="showJobAssistantDrawer"
          v-on="$listeners"
          @switch-drawer="switchDrawer"
          @set-current-tab="setCurrentTab"
          @walkthrough-popover-cta-clicked="setScrollToCommitForm"
        />
      </div>
    </div>
    <commit-section
      v-show="showCommitForm"
      :ref="$options.commitSectionRef"
      :ci-file-content="ciFileContent"
      :commit-sha="commitSha"
      :has-unsaved-changes="hasUnsavedChanges"
      :is-new-ci-config-file="isNewCiConfigFile"
      :scroll-to-commit-form="scrollToCommitForm"
      @scrolled-to-commit-form="setScrollToCommitForm(false)"
      v-on="$listeners"
    />
    <pipeline-editor-drawer
      :is-visible="showHelpDrawer"
      :z-index="drawerIndex[$options.EDITOR_APP_DRAWER_HELP]"
      v-on="$listeners"
      @switch-drawer="switchDrawer"
    />
    <job-assistant-drawer
      :ci-config-data="ciConfigData"
      :ci-file-content="ciFileContent"
      :is-visible="showJobAssistantDrawer"
      :z-index="drawerIndex[$options.EDITOR_APP_DRAWER_JOB_ASSISTANT]"
      v-on="$listeners"
      @switch-drawer="switchDrawer"
    />
  </div>
</template>
