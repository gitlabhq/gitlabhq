<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  components: {
    UserAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    assignees: {
      type: Array,
      required: true,
    },
    iconSize: {
      type: Number,
      required: false,
      default: 24,
    },
    imgCssClasses: {
      type: String,
      required: false,
      default: '',
    },
    maxVisible: {
      type: Number,
      required: false,
      default: 3,
    },
  },
  data() {
    return {
      maxAssignees: 99,
    };
  },
  computed: {
    assigneesToShow() {
      const numShownAssignees = this.assignees.length - this.numHiddenAssignees;
      return this.assignees.slice(0, numShownAssignees);
    },
    assigneesCounterTooltip() {
      return sprintf(__('%{count} more assignees'), { count: this.numHiddenAssignees });
    },
    numHiddenAssignees() {
      if (this.assignees.length > this.maxVisible) {
        return this.assignees.length - this.maxVisible + 1;
      }
      return 0;
    },
    assigneeCounterLabel() {
      if (this.numHiddenAssignees > this.maxAssignees) {
        return `${this.maxAssignees}+`;
      }

      return `+${this.numHiddenAssignees}`;
    },
  },
  methods: {
    avatarUrlTitle(assignee) {
      return sprintf(__('Assigned to %{assigneeName}'), {
        assigneeName: assignee.name,
      });
    },
    // This method is for backward compat
    // since Graph query would return camelCase
    // props while Rails would return snake_case
    webUrl(assignee) {
      return assignee.web_url || assignee.webUrl;
    },
    avatarUrl(assignee) {
      return assignee.avatar_url || assignee.avatarUrl;
    },
  },
};
</script>
<template>
  <div class="issue-assignees">
    <user-avatar-link
      v-for="assignee in assigneesToShow"
      :key="assignee.id"
      :link-href="webUrl(assignee)"
      :img-alt="avatarUrlTitle(assignee)"
      :img-css-classes="imgCssClasses"
      :img-src="avatarUrl(assignee)"
      :img-size="iconSize"
      class="js-no-trigger author-link"
      tooltip-placement="bottom"
      data-qa-selector="assignee_link"
    >
      <span class="js-assignee-tooltip">
        <span class="bold d-block">{{ __('Assignee') }}</span> {{ assignee.name }}
        <span v-if="assignee.username" class="text-white-50">@{{ assignee.username }}</span>
      </span>
    </user-avatar-link>
    <span
      v-if="numHiddenAssignees > 0"
      v-gl-tooltip
      :title="assigneesCounterTooltip"
      class="avatar-counter"
      data-placement="bottom"
      data-qa-selector="avatar_counter_content"
      >{{ assigneeCounterLabel }}</span
    >
  </div>
</template>
