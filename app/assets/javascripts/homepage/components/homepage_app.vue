<script>
import MergeRequestsWidget from './merge_requests_widget.vue';
import ActivityWidget from './activity_widget.vue';
import RecentlyViewedWidget from './recently_viewed_widget.vue';
import TodosWidget from './todos_widget.vue';

export default {
  components: { MergeRequestsWidget, ActivityWidget, TodosWidget, RecentlyViewedWidget },
  props: {
    reviewRequestedPath: {
      type: String,
      required: true,
    },
    assignedToYouPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <h1>{{ __("Today's highlights") }}</h1>
    <div class="gl-grid gl-grid-cols-1 gl-gap-6 md:gl-grid-cols-3">
      <div class="gl-flex gl-flex-col gl-gap-4 md:gl-col-span-2">
        <merge-requests-widget
          :review-requested-path="reviewRequestedPath"
          :assigned-to-you-path="assignedToYouPath"
        />
        <todos-widget />
        <activity-widget />
      </div>
      <div>
        <recently-viewed-widget />
      </div>
    </div>
  </div>
</template>
