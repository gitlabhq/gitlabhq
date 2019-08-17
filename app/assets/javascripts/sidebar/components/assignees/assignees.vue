<script>
import CollapsedAssigneeList from '../assignees/collapsed_assignee_list.vue';
import UncollapsedAssigneeList from '../assignees/uncollapsed_assignee_list.vue';

export default {
  // name: 'Assignees' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'Assignees',
  components: {
    CollapsedAssigneeList,
    UncollapsedAssigneeList,
  },
  props: {
    rootPath: {
      type: String,
      required: true,
    },
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
      const canMergeUsers = this.users.filter(user => user.can_merge);
      const canNotMergeUsers = this.users.filter(user => !user.can_merge);

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
      <template v-if="hasNoUsers">
        <span class="assign-yourself no-value qa-assign-yourself">
          {{ __('None') }}
          <template v-if="editable">
            -
            <button type="button" class="btn-link" @click="assignSelf">
              {{ __('assign yourself') }}
            </button>
          </template>
        </span>
      </template>

      <uncollapsed-assignee-list
        v-else
        :users="sortedAssigness"
        :root-path="rootPath"
        :issuable-type="issuableType"
      />
    </div>
  </div>
</template>
