<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { deprecatedCreateFlash as Flash } from '~/flash';
import eventHub from '~/sidebar/event_hub';
import Store from '~/sidebar/stores/sidebar_store';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReviewerTitle from './reviewer_title.vue';
import Reviewers from './reviewers.vue';
import { __ } from '~/locale';

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
    signedIn: {
      type: Boolean,
      required: false,
      default: false,
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
          // Uncomment once this issue has been addressed > https://gitlab.com/gitlab-org/gitlab/-/issues/237922
          // refreshUserMergeRequestCounts();
        })
        .catch(() => {
          this.loading = false;
          return new Flash(__('Error occurred when saving reviewers'));
        });
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
      :show-toggle="!signedIn"
    />
    <reviewers
      v-if="!store.isFetching.reviewers"
      :root-path="relativeUrlRoot"
      :users="store.reviewers"
      :editable="store.editable"
      :issuable-type="issuableType"
      class="value"
    />
  </div>
</template>
