<script>
import { __ } from '~/locale';
import IndexLayout from '~/vue_shared/components/index_layout.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GreetingHeader from './greeting_header.vue';
import ActivityWidget from './activity_widget.vue';
import QuickAccessWidget from './quick_access_widget.vue';
import MergeRequestsWidget from './merge_requests_widget.vue';
import PipelinesWidget from './pipelines_widget.vue';
import TodosWidget from './todos_widget.vue';
import PickUpWidget from './pick_up_widget.vue';

export default {
  name: 'HomepageApp',
  components: {
    IndexLayout,
    GreetingHeader,
    ActivityWidget,
    TodosWidget,
    QuickAccessWidget,
    MergeRequestsWidget,
    PipelinesWidget,
    PickUpWidget,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
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
  computed: {
    shouldShowPickUpWidget() {
      if (!this.lastPushEvent?.create_mr_path) return false;

      // Show widget if we have a push event and either backend says show OR we have valid data
      return Boolean(this.lastPushEvent.show_widget || this.lastPushEvent.branch_name);
    },
  },
  i18n: {
    pageTitle: __('Home'),
  },
};
</script>

<template>
  <index-layout :page-heading-sr-only="true" :heading="$options.i18n.pageTitle">
    <greeting-header />
    <div class="gl-grid gl-grid-cols-1 gl-gap-6 @md/panel:gl-grid-cols-3">
      <section class="gl-flex gl-flex-col gl-gap-6 @md/panel:gl-col-span-2">
        <pick-up-widget v-if="shouldShowPickUpWidget" :last-push-event="lastPushEvent" />
        <todos-widget />
        <activity-widget :activity-path="activityPath" />
      </section>
      <aside class="gl-flex gl-flex-col gl-gap-6">
        <merge-requests-widget />
        <quick-access-widget />
        <pipelines-widget v-if="glFeatures.homepagePipelinesWidget" />
      </aside>
    </div>
  </index-layout>
</template>
