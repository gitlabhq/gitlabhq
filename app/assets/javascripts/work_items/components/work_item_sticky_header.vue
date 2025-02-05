<script>
import { GlLoadingIcon, GlIntersectionObserver, GlButton, GlLink } from '@gitlab/ui';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { findNotesWidget } from '../utils';
import WorkItemActions from './work_item_actions.vue';
import TodosToggle from './shared/todos_toggle.vue';
import WorkItemStateBadge from './work_item_state_badge.vue';
import WorkItemNotificationsWidget from './work_item_notifications_widget.vue';

export default {
  components: {
    LockedBadge,
    GlIntersectionObserver,
    GlLoadingIcon,
    WorkItemActions,
    TodosToggle,
    ConfidentialityBadge,
    WorkItemStateBadge,
    WorkItemNotificationsWidget,
    GlButton,
    GlLink,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    isStickyHeaderShowing: {
      type: Boolean,
      required: true,
    },
    workItemNotificationsSubscribed: {
      type: Boolean,
      required: true,
    },
    updateInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentWorkItemConfidentiality: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentId: {
      type: String,
      required: false,
      default: null,
    },
    showWorkItemCurrentUserTodos: {
      type: Boolean,
      required: false,
      default: false,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    currentUserTodos: {
      type: Array,
      required: false,
      default: () => [],
    },
    workItemAuthorId: {
      type: Number,
      required: false,
      default: 0,
    },
    isGroup: {
      type: Boolean,
      required: true,
    },
    allowedChildTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespaceFullName: {
      type: String,
      required: false,
      default: '',
    },
    hasChildren: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    canUpdate() {
      return this.workItem.userPermissions?.updateWorkItem;
    },
    canDelete() {
      return this.workItem.userPermissions?.deleteWorkItem;
    },
    canReportSpam() {
      return this.workItem.userPermissions?.reportSpam;
    },
    isDiscussionLocked() {
      return findNotesWidget(this.workItem)?.discussionLocked;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItem.workItemType?.id;
    },
    projectFullPath() {
      return this.workItem.namespace?.fullPath;
    },
    workItemState() {
      return this.workItem.state;
    },
    newTodoAndNotificationsEnabled() {
      return this.glFeatures.notificationsTodosButtons;
    },
    widgets() {
      return this.workItem.widgets;
    },
  },
  WORKSPACE_PROJECT,
};
</script>

<template>
  <gl-intersection-observer
    @appear="$emit('hideStickyHeader')"
    @disappear="$emit('showStickyHeader')"
  >
    <transition name="issuable-header-slide">
      <div
        v-if="isStickyHeaderShowing"
        class="issue-sticky-header gl-border-b gl-fixed gl-z-3 gl-bg-default gl-py-2"
        data-testid="work-item-sticky-header"
      >
        <div
          class="work-item-sticky-header-text gl-mx-auto gl-flex gl-items-center gl-gap-3 gl-px-5 xl:gl-px-6"
        >
          <work-item-state-badge v-if="workItemState" :work-item-state="workItemState" />
          <gl-loading-icon v-if="updateInProgress" />
          <confidentiality-badge
            v-if="workItem.confidential"
            :issuable-type="workItemType"
            :workspace-type="$options.WORKSPACE_PROJECT"
            hide-text-in-small-screens
          />
          <locked-badge v-if="isDiscussionLocked" :issuable-type="workItemType" />
          <gl-link
            class="gl-mr-auto gl-block gl-truncate gl-pr-3 gl-font-bold gl-text-strong"
            href="#top"
            :title="workItem.title"
          >
            {{ workItem.title }}
          </gl-link>
          <gl-button
            v-if="canUpdate"
            category="secondary"
            data-testid="work-item-edit-button-sticky"
            class="shortcut-edit-wi-description"
            @click="$emit('toggleEditMode')"
          >
            {{ __('Edit') }}
          </gl-button>
          <todos-toggle
            v-if="showWorkItemCurrentUserTodos"
            :item-id="workItem.id"
            :current-user-todos="currentUserTodos"
            todos-button-type="secondary"
            @todosUpdated="$emit('todosUpdated', $event)"
            @error="updateError = $event"
          />
          <work-item-notifications-widget
            v-if="newTodoAndNotificationsEnabled"
            :full-path="fullPath"
            :work-item-id="workItem.id"
            :subscribed-to-notifications="workItemNotificationsSubscribed"
            :can-update="canUpdate"
            @error="$emit('error')"
          />
          <work-item-actions
            :full-path="fullPath"
            :work-item-id="workItem.id"
            :work-item-iid="workItem.iid"
            :hide-subscribe="newTodoAndNotificationsEnabled"
            :subscribed-to-notifications="workItemNotificationsSubscribed"
            :work-item-type="workItemType"
            :work-item-type-id="workItemTypeId"
            :can-delete="canDelete"
            :can-report-spam="canReportSpam"
            :can-update="canUpdate"
            :is-confidential="workItem.confidential"
            :is-discussion-locked="isDiscussionLocked"
            :is-parent-confidential="parentWorkItemConfidentiality"
            :work-item-reference="workItem.reference"
            :work-item-create-note-email="workItem.createNoteEmail"
            :work-item-state="workItem.state"
            :work-item-web-url="workItem.webUrl"
            :is-modal="isModal"
            :work-item-author-id="workItemAuthorId"
            :is-group="isGroup"
            :widgets="widgets"
            :allowed-child-types="allowedChildTypes"
            :parent-id="parentId"
            :namespace-full-name="namespaceFullName"
            :has-children="hasChildren"
            @deleteWorkItem="$emit('deleteWorkItem')"
            @toggleWorkItemConfidentiality="
              $emit('toggleWorkItemConfidentiality', !workItem.confidential)
            "
            @error="$emit('error')"
            @promotedToObjective="$emit('promotedToObjective')"
            @workItemTypeChanged="$emit('workItemTypeChanged')"
            @workItemStateUpdated="$emit('workItemStateUpdated')"
            @toggleReportAbuseModal="$emit('toggleReportAbuseModal', true)"
          />
        </div>
      </div>
    </transition>
  </gl-intersection-observer>
</template>
