<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { TYPE_ISSUE } from '~/issues/constants';
import UncollapsedReviewerList from './uncollapsed_reviewer_list.vue';

export default {
  // name: 'Reviewers' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Reviewers',
  components: {
    GlButton,
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
    <div class="value hide-collapsed">
      <span
        v-if="hasNoUsers"
        class="no-value gl-display-flex gl-font-base gl-line-height-normal"
        data-testid="no-value"
      >
        {{ __('None') }}
        <template v-if="editable">
          -
          <gl-button
            category="tertiary"
            variant="link"
            class="gl-ml-2"
            data-testid="assign-yourself"
            @click="assignSelf"
          >
            <span class="gl-text-gray-500 gl-hover-text-blue-800">{{ __('assign yourself') }}</span>
          </gl-button>
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
