<script>
import CollapsedAssigneeList from './collapsed_assignee_list.vue';
import UncollapsedAssigneeList from './uncollapsed_assignee_list.vue';

export default {
  // name: 'Assignees' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Assignees',
  components: {
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
      default: 'issue',
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

    <div data-testid="expanded-assignee" class="value hide-collapsed">
      <span v-if="hasNoUsers" class="no-value" data-testid="no-value">
        {{ __('None') }}
        <template v-if="editable">
          -
          <button type="button" class="btn-link" data-testid="assign-yourself" @click="assignSelf">
            {{ __('assign yourself') }}
          </button>
        </template>
      </span>

      <uncollapsed-assignee-list v-else :users="sortedAssigness" :issuable-type="issuableType" />
    </div>
  </div>
</template>
