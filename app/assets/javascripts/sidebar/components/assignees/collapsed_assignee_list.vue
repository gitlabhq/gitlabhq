<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import CollapsedAssignee from './collapsed_assignee.vue';

const DEFAULT_MAX_COUNTER = 99;
const DEFAULT_RENDER_COUNT = 5;

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CollapsedAssignee,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  computed: {
    isMergeRequest() {
      return this.issuableType === 'merge_request';
    },
    hasNoUsers() {
      return !this.users.length;
    },
    hasMoreThanOneAssignee() {
      return this.users.length > 1;
    },
    hasMoreThanTwoAssignees() {
      return this.users.length > 2;
    },
    allAssigneesCanMerge() {
      return this.users.every(user => user.can_merge);
    },
    sidebarAvatarCounter() {
      if (this.users.length > DEFAULT_MAX_COUNTER) {
        return `${DEFAULT_MAX_COUNTER}+`;
      }

      return `+${this.users.length - 1}`;
    },
    collapsedUsers() {
      const collapsedLength = this.hasMoreThanTwoAssignees ? 1 : this.users.length;

      return this.users.slice(0, collapsedLength);
    },
    tooltipTitleMergeStatus() {
      if (!this.isMergeRequest) {
        return '';
      }

      const mergeLength = this.users.filter(u => u.can_merge).length;

      if (mergeLength === this.users.length) {
        return '';
      } else if (mergeLength > 0) {
        return sprintf(__('%{mergeLength}/%{usersLength} can merge'), {
          mergeLength,
          usersLength: this.users.length,
        });
      }

      return this.users.length === 1 ? __('cannot merge') : __('no one can merge');
    },
    tooltipTitle() {
      const maxRender = Math.min(DEFAULT_RENDER_COUNT, this.users.length);
      const renderUsers = this.users.slice(0, maxRender);
      const names = renderUsers.map(u => u.name);

      if (!this.users.length) {
        return __('Assignee(s)');
      }

      if (this.users.length > names.length) {
        names.push(sprintf(__('+ %{amount} more'), { amount: this.users.length - names.length }));
      }

      const text = names.join(', ');

      return this.tooltipTitleMergeStatus ? `${text} (${this.tooltipTitleMergeStatus})` : text;
    },

    tooltipOptions() {
      return { container: 'body', placement: 'left', boundary: 'viewport' };
    },
  },
};
</script>

<template>
  <div
    v-gl-tooltip="tooltipOptions"
    :class="{ 'multiple-users': hasMoreThanOneAssignee }"
    :title="tooltipTitle"
    class="sidebar-collapsed-icon sidebar-collapsed-user"
  >
    <i v-if="hasNoUsers" :aria-label="__('None')" class="fa fa-user"> </i>
    <collapsed-assignee
      v-for="user in collapsedUsers"
      :key="user.id"
      :user="user"
      :issuable-type="issuableType"
    />
    <button v-if="hasMoreThanTwoAssignees" class="btn-link" type="button">
      <span class="avatar-counter sidebar-avatar-counter"> {{ sidebarAvatarCounter }} </span>
      <i
        v-if="isMergeRequest && !allAssigneesCanMerge"
        aria-hidden="true"
        class="fa fa-exclamation-triangle merge-icon"
      ></i>
    </button>
  </div>
</template>
