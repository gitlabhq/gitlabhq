<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import CommitSection from './components/commit/commit_section.vue';
import PipelineEditorDrawer from './components/drawer/pipeline_editor_drawer.vue';
import PipelineEditorFileNav from './components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorHeader from './components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from './components/pipeline_editor_tabs.vue';
import { CREATE_TAB } from './constants';

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
    PipelineEditorFileNav,
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
      currentTab: CREATE_TAB,
      scrollToCommitForm: false,
      shouldLoadNewBranch: false,
      showSwitchBranchModal: false,
    };
  },
  computed: {
    showCommitForm() {
      return this.currentTab === CREATE_TAB;
    },
  },
  methods: {
    closeBranchModal() {
      this.showSwitchBranchModal = false;
    },
    handleConfirmSwitchBranch() {
      this.showSwitchBranchModal = true;
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
      :should-load-new-branch="shouldLoadNewBranch"
      @select-branch="handleConfirmSwitchBranch"
      v-on="$listeners"
    />
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
      :is-new-ci-config-file="isNewCiConfigFile"
      v-on="$listeners"
      @set-current-tab="setCurrentTab"
      @walkthrough-popover-cta-clicked="setScrollToCommitForm"
    />
    <commit-section
      v-if="showCommitForm"
      :ref="$options.commitSectionRef"
      :ci-file-content="ciFileContent"
      :commit-sha="commitSha"
      :is-new-ci-config-file="isNewCiConfigFile"
      :scroll-to-commit-form="scrollToCommitForm"
      @scrolled-to-commit-form="setScrollToCommitForm(false)"
      v-on="$listeners"
    />
    <pipeline-editor-drawer />
  </div>
</template>
