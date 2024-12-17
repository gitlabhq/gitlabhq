<script>
import { GlIcon } from '@gitlab/ui';
import StatusBadge from '~/issuable/components/status_badge.vue';
import { STATUS_OPEN, TYPE_ALERT, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import {
  TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_EPIC,
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_MERGE_REQUEST,
  TODO_TARGET_TYPE_PIPELINE,
  TODO_TARGET_TYPE_SSH_KEY,
} from '../constants';

export default {
  components: {
    StatusBadge,
    GlIcon,
  },
  props: {
    todo: {
      type: Object,
      required: true,
    },
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
        return this.todo.targetEntity?.mergeRequestState;
      }

      if (this.isIssue) {
        return this.todo.targetEntity?.issueState;
      }

      if (this.isAlert) {
        return this.todo.targetEntity?.alertState;
      }

      throw new Error(`Unknown target type: ${this.todo.targetType}`);
    },
    showStatusBadge() {
      return (
        (this.isMergeRequest || this.isIssue || this.isAlert) && this.issuableState !== STATUS_OPEN
      );
    },
    /**
     * Full title line of the todo title + full reference, joined by a middot
     */
    todoTitle() {
      return [this.targetName, this.targetFullReference].filter(Boolean).join(' · ');
    },
    /**
     * Right half of a todo title: Full reference to the todo (parentPath + Target Reference)
     */
    targetFullReference() {
      return [this.parentPath, this.targetReference].filter(Boolean).join(' ');
    },
    /**
     * Left half of a To-Do title, often the entity name
     */
    targetName() {
      if (this.isMemberAccessRequestAction) {
        return '';
      }

      const name = this.todo.targetEntity?.name ?? '';

      if (this.isDesign && this.todo.targetEntity?.issue?.name) {
        if (name) {
          return `${this.todo.targetEntity.issue.name} › ${name}`;
        }
        return this.todo.targetEntity.issue.name;
      }

      return name;
    },
    /**
     * Reference of the target entity
     */
    targetReference() {
      if (this.isDesign && this.todo.targetEntity?.issue?.reference) {
        return this.todo.targetEntity.issue.reference;
      }
      return this.todo.targetEntity?.reference ?? '';
    },
    /**
     * Parent path of the target entity Reference of the target entity
     */
    parentPath() {
      if (this.todo.group) {
        return this.todo.group.fullName;
      }

      if (this.todo.project) {
        return this.todo.project.nameWithNamespace;
      }

      return '';
    },
    icon() {
      switch (this.todo.targetType) {
        case TODO_TARGET_TYPE_ISSUE:
          return 'issues';
        case TODO_TARGET_TYPE_MERGE_REQUEST:
          return 'merge-request';
        case TODO_TARGET_TYPE_PIPELINE:
          return 'pipeline';
        case TODO_TARGET_TYPE_ALERT:
          return 'status-alert';
        case TODO_TARGET_TYPE_DESIGN:
          return 'media';
        case TODO_TARGET_TYPE_SSH_KEY:
          return 'token';
        case TODO_TARGET_TYPE_EPIC:
          return 'epic';
        default:
          return null;
      }
    },
  },
};
</script>

<template>
  <div>
    <status-badge v-if="showStatusBadge" :issuable-type="issuableType" :state="issuableState" />
    <gl-icon v-if="icon" :name="icon" />
    <div class="gl-overflow-hidden gl-text-ellipsis" data-testid="todo-title">
      {{ todoTitle }}
    </div>
  </div>
</template>
