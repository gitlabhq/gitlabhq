<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CommitSection from './components/commit/commit_section.vue';
import PipelineEditorDrawer from './components/drawer/pipeline_editor_drawer.vue';
import JobAssistantDrawer from './components/job_assistant_drawer/job_assistant_drawer.vue';
import PipelineEditorFileNav from './components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorFileTree from './components/file_tree/container.vue';
import PipelineEditorHeader from './components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from './components/pipeline_editor_tabs.vue';
import { CREATE_TAB, FILE_TREE_DISPLAY_KEY } from './constants';

const AiAssistantDrawer = () =>
  import('ee_component/ci/pipeline_editor/components/ai_assistant_drawer.vue');

export default {
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
    AiAssistantDrawer,
    PipelineEditorFileNav,
    PipelineEditorFileTree,
    PipelineEditorHeader,
    PipelineEditorTabs,
  },
  mixins: [glFeatureFlagMixin()],
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
      currentTab: CREATE_TAB,
      scrollToCommitForm: false,
      shouldLoadNewBranch: false,
      showDrawer: false,
      showJobAssistantDrawer: false,
      showAiAssistantDrawer: false,
      drawerIndex: 200,
      jobAssistantIndex: 200,
      aiAssistantIndex: 200,
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
  },
  mounted() {
    this.showFileTree = JSON.parse(localStorage.getItem(FILE_TREE_DISPLAY_KEY)) || false;
  },
  methods: {
    closeBranchModal() {
      this.showSwitchBranchModal = false;
    },
    closeDrawer() {
      this.showDrawer = false;
    },
    closeJobAssistantDrawer() {
      this.showJobAssistantDrawer = false;
    },
    closeAiAssistantDrawer() {
      this.showAiAssistantDrawer = false;
    },
    openAiAssistantDrawer() {
      this.showAiAssistantDrawer = true;
      this.aiAssistantIndex = this.drawerIndex + 1;
    },
    handleConfirmSwitchBranch() {
      this.showSwitchBranchModal = true;
    },
    openDrawer() {
      this.showDrawer = true;
      this.drawerIndex = this.jobAssistantIndex + 1;
    },
    openJobAssistantDrawer() {
      this.showJobAssistantDrawer = true;
      this.jobAssistantIndex = this.drawerIndex + 1;
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
  <div class="gl-transition-medium gl-w-full">
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
    <div class="gl-display-flex gl-w-full gl-sm-flex-direction-column">
      <pipeline-editor-file-tree
        v-if="showFileTree"
        class="gl-flex-shrink-0"
        :includes="includesFiles"
      />
      <div class="gl-flex-grow-1 gl-min-w-0">
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
          :show-drawer="showDrawer"
          :show-job-assistant-drawer="showJobAssistantDrawer"
          :show-ai-assistant-drawer="showAiAssistantDrawer"
          v-on="$listeners"
          @open-drawer="openDrawer"
          @close-drawer="closeDrawer"
          @open-job-assistant-drawer="openJobAssistantDrawer"
          @close-job-assistant-drawer="closeJobAssistantDrawer"
          @open-ai-assistant-drawer="openAiAssistantDrawer"
          @close-ai-assistant-drawer="closeAiAssistantDrawer"
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
      :is-visible="showDrawer"
      :z-index="drawerIndex"
      v-on="$listeners"
      @close-drawer="closeDrawer"
    />
    <job-assistant-drawer
      :ci-config-data="ciConfigData"
      :ci-file-content="ciFileContent"
      :is-visible="showJobAssistantDrawer"
      :z-index="jobAssistantIndex"
      v-on="$listeners"
      @close-job-assistant-drawer="closeJobAssistantDrawer"
    />
    <ai-assistant-drawer
      v-if="glFeatures.aiCiConfigGenerator"
      :is-visible="showAiAssistantDrawer"
      :z-index="aiAssistantIndex"
      @close-ai-assistant-drawer="closeAiAssistantDrawer"
    />
  </div>
</template>
