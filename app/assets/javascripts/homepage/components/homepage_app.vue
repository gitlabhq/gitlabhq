<script>
import MergeRequestsWidget from './merge_requests_widget.vue';
import ActivityWidget from './activity_widget.vue';
import TodosWidget from './todos_widget.vue';

export default {
  components: { MergeRequestsWidget, ActivityWidget, TodosWidget },
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
    <merge-requests-widget
      :review-requested-path="reviewRequestedPath"
      :assigned-to-you-path="assignedToYouPath"
    />
    <todos-widget />
    <activity-widget />
  </div>
</template>
