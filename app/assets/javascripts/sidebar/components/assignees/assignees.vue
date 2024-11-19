<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import CollapsedAssigneeList from './collapsed_assignee_list.vue';
import UncollapsedAssigneeList from './uncollapsed_assignee_list.vue';

export default {
  // name: 'Assignees' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Assignees',
  components: {
    GlButton,
    CollapsedAssigneeList,
    UncollapsedAssigneeList,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
  },
  computed: {
    hasNoUsers() {
      return !this.users.length;
    },
    sortedAssigness() {
      const canMergeUsers = this.users.filter((user) => user.can_merge);
      const canNotMergeUsers = this.users.filter((user) => !user.can_merge);
      return [...canMergeUsers, ...canNotMergeUsers];
    },
  },
  methods: {
    assignSelf() {
      this.$emit('assign-self');
    },
  },
};
</script>

<template>
  <div>
    <collapsed-assignee-list :users="sortedAssigness" :issuable-type="issuableType" />

    <div class="value hide-collapsed">
      <span v-if="hasNoUsers" class="no-value" data-testid="no-value">
        {{ __('None') }}
        <template v-if="editable">
          -
          <gl-button variant="link" data-testid="assign-yourself" @click="assignSelf">
            <span class="gl-text-subtle hover:gl-text-blue-800">{{ __('assign yourself') }}</span>
          </gl-button>
        </template>
      </span>

      <uncollapsed-assignee-list v-else :users="sortedAssigness" :issuable-type="issuableType" />
    </div>
  </div>
</template>
