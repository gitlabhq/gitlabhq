<script>
import { GlLink } from '@gitlab/ui';
import GreetingHeader from './greeting_header.vue';
import MergeRequestsWidget from './merge_requests_widget.vue';
import WorkItemsWidget from './work_items_widget.vue';
import ActivityWidget from './activity_widget.vue';
import RecentlyViewedWidget from './recently_viewed_widget.vue';
import TodosWidget from './todos_widget.vue';

export default {
  components: {
    GlLink,
    GreetingHeader,
    MergeRequestsWidget,
    WorkItemsWidget,
    ActivityWidget,
    TodosWidget,
    RecentlyViewedWidget,
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
      <div>
        <recently-viewed-widget />
      </div>
    </div>
    <div class="gl-mt-5 gl-text-center">
      <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/553938" target="_blank">{{
        __('Leave feedback')
      }}</gl-link>
    </div>
  </div>
</template>
