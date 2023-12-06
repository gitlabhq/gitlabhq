<script>
import IssuableSidebar from '~/vue_shared/issuable/sidebar/components/issuable_sidebar_root.vue';

import IssuableBody from './issuable_body.vue';
import IssuableDiscussion from './issuable_discussion.vue';
import IssuableHeader from './issuable_header.vue';

export default {
  components: {
    IssuableSidebar,
    IssuableHeader,
    IssuableBody,
    IssuableDiscussion,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    statusIcon: {
      type: String,
      required: false,
      default: '',
    },
    statusIconClass: {
      type: String,
      required: false,
      default: '',
    },
    enableEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideEditButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableAutosave: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableZenMode: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableTaskList: {
      type: Boolean,
      required: false,
      default: false,
    },
    editFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    showFieldTitle: {
      type: Boolean,
      required: false,
      default: false,
    },
    descriptionPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    descriptionHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    taskCompletionStatus: {
      type: Object,
      required: false,
      default: null,
    },
    taskListUpdatePath: {
      type: String,
      required: false,
      default: '',
    },
    taskListLockVersion: {
      type: Number,
      required: false,
      default: 0,
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    workspaceType: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    handleKeydownTitle(e, issuableMeta) {
      this.$emit('keydown-title', e, issuableMeta);
    },
    handleKeydownDescription(e, issuableMeta) {
      this.$emit('keydown-description', e, issuableMeta);
    },
  },
};
</script>

<template>
  <div class="issuable-show-container" data-testid="issuable-show-container">
    <issuable-header
      :issuable-state="issuable.state"
      :status-icon="statusIcon"
      :status-icon-class="statusIconClass"
      :blocked="issuable.blocked"
      :confidential="issuable.confidential"
      :created-at="issuable.createdAt"
      :author="issuable.author"
      :task-completion-status="taskCompletionStatus"
      :issuable-type="issuable.type"
      :workspace-type="workspaceType"
      :show-work-item-type-icon="showWorkItemTypeIcon"
    >
      <template #status-badge>
        <slot name="status-badge"></slot>
      </template>
      <template #header-actions>
        <slot name="header-actions"></slot>
      </template>
    </issuable-header>

    <issuable-body
      :issuable="issuable"
      :status-icon="statusIcon"
      :status-icon-class="statusIconClass"
      :enable-edit="enableEdit"
      :hide-edit-button="hideEditButton"
      :enable-autocomplete="enableAutocomplete"
      :enable-autosave="enableAutosave"
      :enable-zen-mode="enableZenMode"
      :enable-task-list="enableTaskList"
      :edit-form-visible="editFormVisible"
      :show-field-title="showFieldTitle"
      :description-preview-path="descriptionPreviewPath"
      :description-help-path="descriptionHelpPath"
      :task-list-update-path="taskListUpdatePath"
      :task-list-lock-version="taskListLockVersion"
      :workspace-type="workspaceType"
      @edit-issuable="$emit('edit-issuable', $event)"
      @task-list-update-success="$emit('task-list-update-success', $event)"
      @task-list-update-failure="$emit('task-list-update-failure')"
      @keydown-title="handleKeydownTitle"
      @keydown-description="handleKeydownDescription"
    >
      <template #status-badge>
        <slot name="status-badge"></slot>
      </template>
      <template #edit-form-actions="actionsProps">
        <slot name="edit-form-actions" v-bind="actionsProps"></slot>
      </template>
    </issuable-body>

    <issuable-discussion>
      <template #discussion>
        <slot name="discussion"></slot>
      </template>
    </issuable-discussion>

    <issuable-sidebar>
      <template #right-sidebar-top-items="{ sidebarExpanded, toggleSidebar }">
        <slot name="right-sidebar-top-items" v-bind="{ sidebarExpanded, toggleSidebar }"></slot>
      </template>
      <template #right-sidebar-items="{ sidebarExpanded, toggleSidebar }">
        <slot name="right-sidebar-items" v-bind="{ sidebarExpanded, toggleSidebar }"></slot>
      </template>
    </issuable-sidebar>
  </div>
</template>
