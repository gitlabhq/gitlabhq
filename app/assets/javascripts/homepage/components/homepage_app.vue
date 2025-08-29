<script>
import GreetingHeader from './greeting_header.vue';
import HomepagePreferencesBanner from './homepage_preferences_banner.vue';
import MergeRequestsWidget from './merge_requests_widget.vue';
import WorkItemsWidget from './work_items_widget.vue';
import ActivityWidget from './activity_widget.vue';
import RecentlyViewedWidget from './recently_viewed_widget.vue';
import TodosWidget from './todos_widget.vue';
import FeedbackWidget from './feedback_widget.vue';

export default {
  components: {
    GreetingHeader,
    HomepagePreferencesBanner,
    MergeRequestsWidget,
    WorkItemsWidget,
    ActivityWidget,
    TodosWidget,
    RecentlyViewedWidget,
    FeedbackWidget,
  },
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
  },
};
</script>

<template>
  <div>
    <greeting-header />
    <homepage-preferences-banner />
    <div class="gl-grid gl-grid-cols-1 gl-gap-6 @md/panel:gl-grid-cols-3">
      <div class="gl-flex gl-flex-col gl-gap-6 @md/panel:gl-col-span-2">
        <div class="gl-grid gl-grid-cols-1 gl-gap-5 @lg/panel:gl-grid-cols-2">
          <merge-requests-widget
            :review-requested-path="reviewRequestedPath"
            :assigned-to-you-path="assignedMergeRequestsPath"
          />
          <work-items-widget
            :assigned-to-you-path="assignedWorkItemsPath"
            :authored-by-you-path="authoredWorkItemsPath"
          />
        </div>
        <todos-widget />
        <activity-widget :activity-path="activityPath" />
      </div>
      <div class="gl-flex gl-flex-col gl-gap-6">
        <recently-viewed-widget />
        <feedback-widget />
      </div>
    </div>
  </div>
</template>
