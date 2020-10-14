<script>
import IssuableSidebar from '~/issuable_sidebar/components/issuable_sidebar_root.vue';

import IssuableHeader from './issuable_header.vue';
import IssuableBody from './issuable_body.vue';

export default {
  components: {
    IssuableSidebar,
    IssuableHeader,
    IssuableBody,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    statusBadgeClass: {
      type: String,
      required: false,
      default: '',
    },
    statusIcon: {
      type: String,
      required: false,
      default: '',
    },
    enableEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: false,
    },
    editFormVisible: {
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
  },
};
</script>

<template>
  <div class="issuable-show-container">
    <issuable-header
      :status-badge-class="statusBadgeClass"
      :status-icon="statusIcon"
      :blocked="issuable.blocked"
      :confidential="issuable.confidential"
      :created-at="issuable.createdAt"
      :author="issuable.author"
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
      :status-badge-class="statusBadgeClass"
      :status-icon="statusIcon"
      :enable-edit="enableEdit"
      :enable-autocomplete="enableAutocomplete"
      :edit-form-visible="editFormVisible"
      :description-preview-path="descriptionPreviewPath"
      :description-help-path="descriptionHelpPath"
      @edit-issuable="$emit('edit-issuable', $event)"
    >
      <template #status-badge>
        <slot name="status-badge"></slot>
      </template>
      <template #edit-form-actions="actionsProps">
        <slot name="edit-form-actions" v-bind="actionsProps"></slot>
      </template>
    </issuable-body>
    <issuable-sidebar @sidebar-toggle="$emit('sidebar-toggle', $event)">
      <template #right-sidebar-items="sidebarProps">
        <slot name="right-sidebar-items" v-bind="sidebarProps"></slot>
      </template>
    </issuable-sidebar>
  </div>
</template>
