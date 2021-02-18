<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { isUserBusy } from '~/set_status_modal/utils';
import CollapsedAssignee from './collapsed_assignee.vue';

const DEFAULT_MAX_COUNTER = 99;
const DEFAULT_RENDER_COUNT = 5;

const generateCollapsedAssigneeTooltip = ({ renderUsers, allUsers, tooltipTitleMergeStatus }) => {
  const names = renderUsers.map(({ name, availability }) => {
    if (availability && isUserBusy(availability)) {
      return sprintf(__('%{name} (Busy)'), { name });
    }
    return name;
  });

  if (!allUsers.length) {
    return __('Assignee(s)');
  }
  if (allUsers.length > names.length) {
    names.push(sprintf(__('+ %{amount} more'), { amount: allUsers.length - names.length }));
  }
  const text = names.join(', ');
  return tooltipTitleMergeStatus ? `${text} (${tooltipTitleMergeStatus})` : text;
};

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CollapsedAssignee,
    GlIcon,
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
      return this.users.every((user) => user.can_merge);
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

      const mergeLength = this.users.filter((u) => u.can_merge).length;

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
      return generateCollapsedAssigneeTooltip({
        renderUsers,
        allUsers: this.users,
        tooltipTitleMergeStatus: this.tooltipTitleMergeStatus,
      });
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
    <gl-icon v-if="hasNoUsers" name="user" :aria-label="__('None')" />
    <collapsed-assignee
      v-for="user in collapsedUsers"
      :key="user.id"
      :user="user"
      :issuable-type="issuableType"
    />
    <button v-if="hasMoreThanTwoAssignees" class="btn-link" type="button">
      <span class="avatar-counter sidebar-avatar-counter"> {{ sidebarAvatarCounter }} </span>
      <gl-icon
        v-if="isMergeRequest && !allAssigneesCanMerge"
        name="warning-solid"
        aria-hidden="true"
        class="merge-icon"
      />
    </button>
  </div>
</template>
