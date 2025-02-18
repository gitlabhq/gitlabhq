<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import Vue from 'vue';
import { MountingPortal } from 'portal-vue';
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { __ } from '~/locale';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import ReviewerDrawer from '~/merge_requests/components/reviewers/reviewer_drawer.vue';
import eventHub from '../../event_hub';
import getMergeRequestReviewersQuery from '../../queries/get_merge_request_reviewers.query.graphql';
import mergeRequestReviewersUpdatedSubscription from '../../queries/merge_request_reviewers.subscription.graphql';
import Store from '../../stores/sidebar_store';
import ReviewerTitle from './reviewer_title.vue';
import Reviewers from './reviewers.vue';

export const state = Vue.observable({
  issuable: {},
  loading: false,
  initialLoading: true,
  drawerOpen: false,
});

export default {
  name: 'SidebarReviewers',
  components: {
    MountingPortal,
    GlButton,
    ReviewerTitle,
    Reviewers,
    ReviewerDrawer,
    ApprovalSummary: () =>
      import('ee_component/merge_requests/components/reviewers/approval_summary.vue'),
  },
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
      default: TYPE_ISSUE,
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
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    issuable: {
      query: getMergeRequestReviewersQuery,
      variables() {
        return {
          iid: this.issuableIid,
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.workspace?.issuable;
      },
      result() {
        this.initialLoading = false;
      },
      error() {
        createAlert({ message: __('An error occurred while fetching reviewers.') });
      },
      subscribeToMore: {
        document() {
          return mergeRequestReviewersUpdatedSubscription;
        },
        variables() {
          return {
            issuableId: this.issuable?.id,
          };
        },
        skip() {
          return !this.issuable?.id;
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { mergeRequestReviewersUpdated },
            },
          },
        ) {
          if (mergeRequestReviewersUpdated) {
            this.store.setReviewersFromRealtime(
              mergeRequestReviewersUpdated.reviewers.nodes.map((r) => ({
                ...r,
                id: getIdFromGraphQLId(r.id),
              })),
            );
          }
        },
      },
    },
  },
  data() {
    return state;
  },
  computed: {
    relativeUrlRoot() {
      return gon.relative_url_root ?? '';
    },
    reviewers() {
      return this.issuable.reviewers?.nodes || [];
    },
    graphqlFetching() {
      return this.$apollo.queries.issuable.loading;
    },
    isLoading() {
      return this.loading || this.$apollo.queries.issuable.loading;
    },
    canUpdate() {
      return this.issuable.userPermissions?.adminMergeRequest || false;
    },
  },
  created() {
    this.store = new Store();

    this.removeReviewer = this.store.removeReviewer.bind(this.store);
    this.addReviewer = this.store.addReviewer.bind(this.store);
    this.removeAllReviewers = this.store.removeAllReviewers.bind(this.store);

    // Get events from deprecatedJQueryDropdown
    eventHub.$on('sidebar.removeReviewer', this.removeReviewer);
    eventHub.$on('sidebar.addReviewer', this.addReviewer);
    eventHub.$on('sidebar.removeAllReviewers', this.removeAllReviewers);
    eventHub.$on('sidebar.saveReviewers', this.saveReviewers);
    eventHub.$on('sidebar.toggleReviewerDrawer', this.toggleDrawerOpen);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeReviewer', this.removeReviewer);
    eventHub.$off('sidebar.addReviewer', this.addReviewer);
    eventHub.$off('sidebar.removeAllReviewers', this.removeAllReviewers);
    eventHub.$off('sidebar.saveReviewers', this.saveReviewers);
    eventHub.$off('sidebar.toggleReviewerDrawer', this.toggleDrawerOpen);
  },
  methods: {
    reviewBySelf() {
      // Notify gl dropdown that we are now assigning to current user
      this.$el.parentElement.dispatchEvent(new Event('assignYourself'));

      this.mediator.addSelfReview();
      this.saveReviewers();
    },
    saveReviewers() {
      this.loading = true;

      this.mediator
        .saveReviewers(this.field)
        .then(() => {
          this.loading = false;
          fetchUserCounts();
          this.$apollo.queries.issuable.refetch();
        })
        .catch(() => {
          this.loading = false;
          return createAlert({
            message: __('Error occurred when saving reviewers'),
          });
        });
    },
    requestReview(data) {
      this.mediator.requestReview(data);
    },
    async removeReviewerById(event) {
      const userId = isGid(event.userId) ? getIdFromGraphQLId(event.userId) : event.userId;
      this.store.reviewers = this.store.reviewers.filter((user) => user.id !== userId);
      try {
        await this.saveReviewers();
      } catch (error) {
        createAlert(__('Unable to remove a reviewer at the moment, try again later'), { error });
      } finally {
        event.done();
      }
    },
    toggleDrawerOpen(drawerOpen = !this.drawerOpen) {
      this.drawerOpen = drawerOpen;
    },
  },
};
</script>

<template>
  <div>
    <reviewer-title
      :reviewers="reviewers"
      :number-of-reviewers="reviewers.length"
      :loading="isLoading"
      :editable="canUpdate"
      @request-review="requestReview"
      @remove-reviewer="removeReviewerById"
    />
    <approval-summary short-text class="gl-mb-2">
      <gl-button
        v-if="canUpdate"
        size="small"
        category="tertiary"
        variant="confirm"
        class="gl-ml-2 !gl-text-sm"
        data-testid="sidebar-reviewers-assign-buton"
        @click="toggleDrawerOpen()"
      >
        {{ __('Assign') }}
      </gl-button>
    </approval-summary>
    <reviewers
      v-if="!initialLoading"
      :root-path="relativeUrlRoot"
      :users="reviewers"
      :editable="canUpdate"
      :issuable-type="issuableType"
      class="gl-pt-2"
      @request-review="requestReview"
      @assign-self="reviewBySelf"
      @remove-reviewer="removeReviewerById"
    />
    <mounting-portal mount-to="#js-reviewer-drawer-portal">
      <reviewer-drawer
        :open="drawerOpen"
        @request-review="requestReview"
        @remove-reviewer="removeReviewerById"
        @close="toggleDrawerOpen(false)"
      />
    </mounting-portal>
  </div>
</template>
