<script>
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  createUserCountsManager,
  userCounts,
  useCachedUserCounts,
} from '~/super_sidebar/user_counts_manager';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_MERGE_REQUESTS,
  TRACKING_PROPERTY_REVIEW_REQUESTED,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
  TRACKING_PROPERTY_AUTHORED_BY_YOU,
  TRACKING_LABEL_WORK_ITEMS,
} from '../tracking_constants';
import mergeRequestsWidgetMetadataQuery from '../graphql/queries/merge_requests_widget_metadata.query.graphql';
import workItemsWidgetMetadataQuery from '../graphql/queries/work_items_widget_metadata.query.graphql';
import GreetingHeader from './greeting_header.vue';
import HomepagePreferencesBanner from './homepage_preferences_banner.vue';
import UserItemsCountWidget from './user_items_count_widget.vue';
import ActivityWidget from './activity_widget.vue';
import RecentlyViewedWidget from './recently_viewed_widget.vue';
import TodosWidget from './todos_widget.vue';
import PickUpWidget from './pick_up_widget.vue';
import FeedbackWidget from './feedback_widget.vue';
import BaseWidget from './base_widget.vue';

export default {
  components: {
    GreetingHeader,
    HomepagePreferencesBanner,
    ActivityWidget,
    TodosWidget,
    RecentlyViewedWidget,
    PickUpWidget,
    FeedbackWidget,
    UserItemsCountWidget,
    BaseWidget,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['duoCodeReviewBotUsername'],
  props: {
    reviewRequestedPath: {
      type: String,
      required: true,
    },
    assignedMergeRequestsPath: {
      type: String,
      required: true,
    },
    assignedWorkItemsPath: {
      type: String,
      required: true,
    },
    authoredWorkItemsPath: {
      type: String,
      required: true,
    },
    activityPath: {
      type: String,
      required: true,
    },
    lastPushEvent: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      mergeRequestsMetadata: {},
      mergeRequestsHaveError: false,
      workItemsMetadata: {},
      workItemsHaveError: false,
    };
  },
  apollo: {
    mergeRequestsMetadata: {
      query: mergeRequestsWidgetMetadataQuery,
      variables() {
        return {
          duoCodeReviewBotUsername: this.duoCodeReviewBotUsername,
        };
      },
      update({ currentUser }) {
        return currentUser;
      },
      error(error) {
        this.mergeRequestsHaveError = true;
        Sentry.captureException(error);
      },
    },
    workItemsMetadata: {
      query: workItemsWidgetMetadataQuery,
      variables() {
        return { username: gon?.current_username || null };
      },
      update({ currentUser }) {
        return currentUser;
      },
      error(error) {
        this.workItemsHaveError = true;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    shouldShowPickUpWidget() {
      if (!this.lastPushEvent) return false;

      // Show widget if we have a push event and either backend says show OR we have valid data
      return Boolean(this.lastPushEvent.show_widget || this.lastPushEvent.branch_name);
    },
    reviewRequestedData() {
      return this.mergeRequestsMetadata?.reviewRequestedMergeRequests;
    },
    assignedMergeRequestsData() {
      return this.mergeRequestsMetadata?.assignedMergeRequests;
    },
    assignedWorkItemsData() {
      if (!this.workItemsMetadata.assigned) return null;
      const count = userCounts.assigned_issues ?? null;

      return {
        ...this.workItemsMetadata.assigned,
        count,
      };
    },
    authoredWorkItemsData() {
      return this.workItemsMetadata?.authored;
    },
  },
  created() {
    createUserCountsManager();

    if (userCounts.assigned_issues === null) {
      useCachedUserCounts();
      fetchUserCounts();
    }
  },
  methods: {
    handleReviewRequestedClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_MERGE_REQUESTS,
        property: TRACKING_PROPERTY_REVIEW_REQUESTED,
      });
    },
    handleAssignedMergeRequestsClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_MERGE_REQUESTS,
        property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
      });
    },
    handleAssignedWorkItemsClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_WORK_ITEMS,
        property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
      });
    },
    handleAuthoredWorkItemsClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_WORK_ITEMS,
        property: TRACKING_PROPERTY_AUTHORED_BY_YOU,
      });
    },
    reloadUserCounts() {
      this.mergeRequestsHaveError = false;
      this.workItemsHaveError = false;
      this.$apollo.queries.mergeRequestsMetadata.refetch();
      this.$apollo.queries.workItemsMetadata.refetch();
    },
    handleUserCountsVisible() {
      this.reloadUserCounts();
    },
  },
  i18n: {
    mergeRequestsErrorText: s__(
      'HomePageMergeRequestsWidget|The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.',
    ),
    workItemsErrorText: s__(
      'HomePageWorkItemsWidget|The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
    ),
  },
};
</script>

<template>
  <div>
    <greeting-header />
    <homepage-preferences-banner />
    <div class="gl-grid gl-grid-cols-1 gl-gap-6 @md/panel:gl-grid-cols-3">
      <section class="gl-flex gl-flex-col gl-gap-6 @md/panel:gl-col-span-2">
        <base-widget
          class="gl-grid gl-grid-cols-2 gl-gap-5 @lg/panel:gl-grid-cols-4"
          :apply-default-styling="false"
          @visible="handleUserCountsVisible"
        >
          <user-items-count-widget
            data-testid="review-requested-widget"
            :has-error="mergeRequestsHaveError"
            :error-text="$options.i18n.mergeRequestsErrorText"
            :card-text="s__('HomePageMergeRequestsWidget|Merge requests')"
            :link-text="s__('HomePageMergeRequestsWidget|Waiting for your review')"
            :path="reviewRequestedPath"
            :user-items="reviewRequestedData"
            :icon-name="'merge-request'"
            @click-link="handleReviewRequestedClick"
          />
          <user-items-count-widget
            data-testid="assigned-merge-requests-widget"
            :has-error="mergeRequestsHaveError"
            :error-text="$options.i18n.mergeRequestsErrorText"
            :card-text="s__('HomePageMergeRequestsWidget|Merge requests')"
            :link-text="s__('HomePageMergeRequestsWidget|Assigned to you')"
            :path="assignedMergeRequestsPath"
            :user-items="assignedMergeRequestsData"
            :icon-name="'merge-request'"
            @click-link="handleAssignedMergeRequestsClick"
          />
          <user-items-count-widget
            data-testid="assigned-work-items-widget"
            :has-error="workItemsHaveError"
            :error-text="$options.i18n.workItemsErrorText"
            :card-text="s__('HomePageWorkItemsWidget|Issues')"
            :link-text="s__('HomePageWorkItemsWidget|Assigned to you')"
            :path="assignedWorkItemsPath"
            :user-items="assignedWorkItemsData"
            :icon-name="'work-item-issue'"
            @click-link="handleAssignedWorkItemsClick"
          />
          <user-items-count-widget
            data-testid="authored-work-items-widget"
            :has-error="workItemsHaveError"
            :error-text="$options.i18n.workItemsErrorText"
            :card-text="s__('HomePageWorkItemsWidget|Issues')"
            :link-text="s__('HomePageWorkItemsWidget|Authored by you')"
            :path="authoredWorkItemsPath"
            :user-items="authoredWorkItemsData"
            :icon-name="'work-item-issue'"
            @click-link="handleAuthoredWorkItemsClick"
          />
        </base-widget>
        <pick-up-widget v-if="shouldShowPickUpWidget" :last-push-event="lastPushEvent" />
        <todos-widget />
        <activity-widget :activity-path="activityPath" />
      </section>
      <aside class="gl-flex gl-flex-col gl-gap-6">
        <recently-viewed-widget />
        <feedback-widget />
      </aside>
    </div>
  </div>
</template>
