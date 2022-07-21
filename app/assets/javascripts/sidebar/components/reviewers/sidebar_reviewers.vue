<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import createFlash from '~/flash';
import { __ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Store from '~/sidebar/stores/sidebar_store';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReviewerTitle from './reviewer_title.vue';
import Reviewers from './reviewers.vue';

export default {
  name: 'SidebarReviewers',
  components: {
    ReviewerTitle,
    Reviewers,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    mediator: {
      type: Object,
      required: true,
    },
    field: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    issuableIid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      store: new Store(),
      loading: false,
    };
  },
  computed: {
    relativeUrlRoot() {
      return gon.relative_url_root ?? '';
    },
  },
  created() {
    this.removeReviewer = this.store.removeReviewer.bind(this.store);
    this.addReviewer = this.store.addReviewer.bind(this.store);
    this.removeAllReviewers = this.store.removeAllReviewers.bind(this.store);

    // Get events from deprecatedJQueryDropdown
    eventHub.$on('sidebar.removeReviewer', this.removeReviewer);
    eventHub.$on('sidebar.addReviewer', this.addReviewer);
    eventHub.$on('sidebar.removeAllReviewers', this.removeAllReviewers);
    eventHub.$on('sidebar.saveReviewers', this.saveReviewers);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeReviewer', this.removeReviewer);
    eventHub.$off('sidebar.addReviewer', this.addReviewer);
    eventHub.$off('sidebar.removeAllReviewers', this.removeAllReviewers);
    eventHub.$off('sidebar.saveReviewers', this.saveReviewers);
  },
  methods: {
    saveReviewers() {
      this.loading = true;

      this.mediator
        .saveReviewers(this.field)
        .then(() => {
          this.loading = false;
          refreshUserMergeRequestCounts();
        })
        .catch(() => {
          this.loading = false;
          return createFlash({
            message: __('Error occurred when saving reviewers'),
          });
        });
    },
    requestReview(data) {
      this.mediator.requestReview(data);
    },
  },
};
</script>

<template>
  <div>
    <reviewer-title
      :number-of-reviewers="store.reviewers.length"
      :loading="loading || store.isFetching.reviewers"
      :editable="store.editable"
    />
    <reviewers
      v-if="!store.isFetching.reviewers"
      :root-path="relativeUrlRoot"
      :users="store.reviewers"
      :editable="store.editable"
      :issuable-type="issuableType"
      @request-review="requestReview"
    />
  </div>
</template>
