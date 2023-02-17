<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { TYPE_ISSUE } from '~/issues/constants';
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
      default: TYPE_ISSUE,
    },
  },
  computed: {
    hasNoUsers() {
      return !this.users.length;
    },
    sortedReviewers() {
      const canMergeUsers = this.users.filter((user) => user.mergeRequestInteraction?.canMerge);
      const canNotMergeUsers = this.users.filter((user) => !user.mergeRequestInteraction?.canMerge);

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
      <span v-if="hasNoUsers" class="no-value" data-testid="no-value">
        {{ __('None') }}
        <template v-if="editable">
          -
          <button
            type="button"
            class="gl-button btn-link gl-reset-color!"
            data-testid="assign-yourself"
            data-qa-selector="assign_yourself_button"
            @click="assignSelf"
          >
            {{ __('assign yourself') }}
          </button>
        </template>
      </span>

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
