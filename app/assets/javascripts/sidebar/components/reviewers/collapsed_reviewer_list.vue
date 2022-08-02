<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import CollapsedReviewer from './collapsed_reviewer.vue';

const DEFAULT_MAX_COUNTER = 99;
const DEFAULT_RENDER_COUNT = 5;

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CollapsedReviewer,
    GlIcon,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasNoUsers() {
      return !this.users.length;
    },
    hasMoreThanOneReviewer() {
      return this.users.length > 1;
    },
    hasMoreThanTwoReviewers() {
      return this.users.length > 2;
    },
    allReviewersCanMerge() {
      return this.users.every((user) => user.mergeRequestInteraction?.canMerge);
    },
    sidebarAvatarCounter() {
      if (this.users.length > DEFAULT_MAX_COUNTER) {
        return `${DEFAULT_MAX_COUNTER}+`;
      }

      return `+${this.users.length - 1}`;
    },
    collapsedUsers() {
      const collapsedLength = this.hasMoreThanTwoReviewers ? 1 : this.users.length;

      return this.users.slice(0, collapsedLength);
    },
    tooltipTitleMergeStatus() {
      const mergeLength = this.users.filter((u) => u.mergeRequestInteraction?.canMerge).length;

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
      const names = renderUsers.map((u) => u.name);

      if (!this.users.length) {
        return __('Reviewer(s)');
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
    :class="{ 'multiple-users gl-relative': hasMoreThanOneReviewer }"
    :title="tooltipTitle"
    class="sidebar-collapsed-icon sidebar-collapsed-user"
  >
    <gl-icon v-if="hasNoUsers" name="user" :aria-label="__('None')" />
    <collapsed-reviewer v-for="user in collapsedUsers" :key="user.id" :user="user" />
    <button v-if="hasMoreThanTwoReviewers" class="btn-link gl-button" type="button">
      <span
        class="avatar-counter sidebar-avatar-counter gl-display-flex gl-align-items-center gl-pl-3"
      >
        {{ sidebarAvatarCounter }}
      </span>
      <gl-icon
        v-if="!allReviewersCanMerge"
        name="warning-solid"
        aria-hidden="true"
        class="merge-icon"
      />
    </button>
  </div>
</template>
