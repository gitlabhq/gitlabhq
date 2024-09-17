<script>
import StatusBadge from '~/issuable/components/status_badge.vue';
import { s__ } from '~/locale';
import { STATUS_OPEN, TYPE_ALERT, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import {
  TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_MERGE_REQUEST,
} from '../constants';

export default {
  components: {
    StatusBadge,
  },
  props: {
    todo: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    isIssue() {
      return this.todo.targetType === TODO_TARGET_TYPE_ISSUE;
    },
    isMergeRequest() {
      return this.todo.targetType === TODO_TARGET_TYPE_MERGE_REQUEST;
    },
    isAlert() {
      return this.todo.targetType === TODO_TARGET_TYPE_ALERT;
    },
    isDesign() {
      return this.todo.targetType === TODO_TARGET_TYPE_DESIGN;
    },
    isMemberAccessRequestAction() {
      return this.todo.action === TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED;
    },
    issuableType() {
      if (this.isMergeRequest) {
        return TYPE_MERGE_REQUEST;
      }

      if (this.isIssue) {
        return TYPE_ISSUE;
      }

      if (this.isAlert) {
        return TYPE_ALERT;
      }

      throw new Error(`Unknown target type: ${this.todo.targetType}`);
    },
    issuableState() {
      if (this.isMergeRequest) {
        return this.todo.target.mergeRequestState;
      }

      if (this.isIssue) {
        return this.todo.target.issueState;
      }

      if (this.isAlert) {
        return this.todo.target.alertState;
      }

      throw new Error(`Unknown target type: ${this.todo.targetType}`);
    },
    showStatusBadge() {
      return (
        (this.isMergeRequest || this.isIssue || this.isAlert) && this.issuableState !== STATUS_OPEN
      );
    },
    hasTitle() {
      return this.todo.target && !this.isDesign && !this.isMemberAccessRequestAction;
    },
    targetTitle() {
      if (!this.hasTitle) {
        return '';
      }

      return this.todo.target.title;
    },
    targetReference() {
      return this.todo.target.reference ?? '';
    },
    targetPath() {
      return this.todo.targetPath;
    },
    parentPath() {
      if (this.todo.group) {
        return this.todo.group.fullName;
      }

      return this.todo.project.nameWithNamespace;
    },
  },
  i18n: {
    removed: s__('Todos|(removed)'),
  },
};
</script>

<template>
  <div
    class="gl-flex gl-items-center gl-gap-2 gl-overflow-hidden gl-whitespace-nowrap gl-px-2 gl-pb-3 gl-pt-2 gl-text-sm gl-text-subtle sm:gl-mr-0 sm:gl-pr-4 md:gl-mb-1"
  >
    <status-badge v-if="showStatusBadge" :issuable-type="issuableType" :state="issuableState" />
    <div class="gl-overflow-hidden gl-text-ellipsis">
      <span v-if="hasTitle" class="todo-target-title">{{ targetTitle }}</span>
      <span v-if="!isDesign && !isMemberAccessRequestAction">&middot;</span>
      <span>{{ parentPath }}</span>
      <span v-if="targetReference">{{ targetReference }}</span>
      <span v-else>{{ $options.i18n.removed }}</span>
    </div>
  </div>
</template>
