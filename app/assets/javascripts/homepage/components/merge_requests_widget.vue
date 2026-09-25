<script>
import { GlBadge, GlSkeletonLoader, GlTab, GlTabs } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { TRACKING_PROPERTY_ASSIGNED_TO_YOU } from '../tracking_constants';
import mergeRequestsWidgetQuery from '../graphql/queries/merge_requests_widget.query.graphql';
import BaseWidget from './base_widget.vue';
import MergeRequestsWidgetList from './merge_requests_widget_list.vue';

const N_SKELETON_ROWS = 4;

export default {
  name: 'MergeRequestsWidget',
  components: {
    BaseWidget,
    GlBadge,
    GlSkeletonLoader,
    GlTab,
    GlTabs,
    MergeRequestsWidgetList,
  },
  data() {
    return {
      mergeRequests: null,
      hasError: false,
    };
  },
  apollo: {
    mergeRequests: {
      query: mergeRequestsWidgetQuery,
      update({ currentUser }) {
        return {
          assigned: currentUser?.assignedMergeRequests ?? { count: 0, nodes: [] },
        };
      },
      error(error) {
        this.hasError = true;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.mergeRequests.loading;
    },
    assigned() {
      return this.mergeRequests?.assigned ?? { count: 0, nodes: [] };
    },
  },
  methods: {
    reload() {
      this.hasError = false;
      this.$apollo.queries.mergeRequests.refetch();
    },
    countSrText(count) {
      return n__('%d merge request', '%d merge requests', count);
    },
  },
  i18n: {
    title: s__('HomePageMergeRequestsWidget|Merge requests'),
    assignedTabTitle: s__('HomePageMergeRequestsWidget|Assigned to you'),
    assignedEmptyText: s__('HomePageMergeRequestsWidget|No merge requests assigned to you.'),
    errorText: s__(
      'HomePageMergeRequestsWidget|Could not load your merge requests. Refresh the page to try again.',
    ),
  },
  trackingPropertyAssignedToYou: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
  N_SKELETON_ROWS,
};
</script>

<template>
  <base-widget
    class="homepage-merge-requests-widget"
    data-testid="homepage-merge-requests-widget"
    @visible="reload"
  >
    <h2 class="gl-heading-4 gl-mb-3">{{ $options.i18n.title }}</h2>

    <p v-if="hasError" class="gl-mb-0" data-testid="error-message">
      {{ $options.i18n.errorText }}
    </p>

    <div v-else-if="isLoading" class="gl-flex gl-flex-col gl-gap-5" data-testid="loading-state">
      <gl-skeleton-loader v-for="i in $options.N_SKELETON_ROWS" :key="i" :lines="3" />
    </div>

    <gl-tabs
      v-else
      class="-gl-mx-5"
      nav-class="gl-flex-nowrap gl-whitespace-nowrap gl-overflow-x-auto gl-min-w-0 gl-px-2"
      content-class="gl-px-5 !gl-pb-0 !gl-pt-4"
    >
      <gl-tab>
        <template #title>
          {{ $options.i18n.assignedTabTitle }}
          <gl-badge
            class="homepage-merge-requests-widget-tab-count gl-ml-2"
            variant="neutral"
            aria-hidden="true"
            data-testid="tab-count"
            >{{ assigned.count }}</gl-badge
          >
          <span class="gl-sr-only">{{ countSrText(assigned.count) }}</span>
        </template>
        <merge-requests-widget-list
          :merge-requests="assigned.nodes"
          :empty-text="$options.i18n.assignedEmptyText"
          :tracking-property="$options.trackingPropertyAssignedToYou"
          data-testid="assigned-list"
        />
      </gl-tab>
    </gl-tabs>
  </base-widget>
</template>
