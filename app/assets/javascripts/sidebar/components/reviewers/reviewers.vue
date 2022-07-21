<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import CollapsedReviewerList from './collapsed_reviewer_list.vue';
import UncollapsedReviewerList from './uncollapsed_reviewer_list.vue';

export default {
  // name: 'Reviewers' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Reviewers',
  components: {
    CollapsedReviewerList,
    UncollapsedReviewerList,
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
    sortedReviewers() {
      const canMergeUsers = this.users.filter((user) => user.can_merge);
      const canNotMergeUsers = this.users.filter((user) => !user.can_merge);

      return [...canMergeUsers, ...canNotMergeUsers];
    },
  },
  methods: {
    assignSelf() {
      this.$emit('assign-self');
    },
    requestReview(data) {
      this.$emit('request-review', data);
    },
  },
};
</script>

<template>
  <div>
    <collapsed-reviewer-list :users="sortedReviewers" :issuable-type="issuableType" />

    <div class="value hide-collapsed">
      <template v-if="hasNoUsers">
        <span class="no-value">
          {{ __('None') }}
        </span>
      </template>

      <uncollapsed-reviewer-list
        v-else
        :users="sortedReviewers"
        :root-path="rootPath"
        :issuable-type="issuableType"
        @request-review="requestReview"
      />
    </div>
  </div>
</template>
