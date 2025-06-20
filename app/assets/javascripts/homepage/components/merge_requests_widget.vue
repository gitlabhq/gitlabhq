<script>
import { GlIcon, GlLink, GlBadge } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import mergeRequestsWidgetMetadataQuery from '../graphql/queries/merge_requests_widget_metadata.query.graphql';

export default {
  name: 'MergeRequestsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
  },
  mixins: [timeagoMixin],
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
  data() {
    return {
      metadata: {},
    };
  },
  apollo: {
    metadata: {
      query: mergeRequestsWidgetMetadataQuery,
      update({ currentUser }) {
        return currentUser;
      },
    },
  },
  computed: {
    isLoadingMetadata() {
      return this.$apollo.queries.metadata.loading;
    },
    reviewRequestedCount() {
      return this.metadata?.reviewRequestedMergeRequests?.count ?? 0;
    },
    reviewRequestedLastUpdatedAt() {
      return this.metadata?.reviewRequestedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
    assignedCount() {
      return this.metadata?.assignedMergeRequests?.count ?? 0;
    },
    assignedLastUpdatedAt() {
      return this.metadata?.assignedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
  },
};
</script>

<template>
  <div class="gl-border gl-rounded-lg gl-px-4 gl-py-1">
    <h4 class="gl-flex gl-items-center gl-gap-2">
      <gl-icon name="merge-request" :size="16" />{{ __('Merge requests') }}
    </h4>
    <ul class="gl-list-none gl-p-0">
      <li class="gl-flex gl-items-center gl-gap-3">
        <gl-link :href="reviewRequestedPath">{{ __('Review requested') }}</gl-link>
        <template v-if="!isLoadingMetadata">
          <gl-badge data-testid="review-requested-count">{{ reviewRequestedCount }}</gl-badge>
          <span
            v-if="reviewRequestedLastUpdatedAt"
            data-testid="review-requested-last-updated-at"
            class="gl-ml-auto gl-text-subtle"
            >{{ timeFormatted(reviewRequestedLastUpdatedAt) }}</span
          >
        </template>
      </li>
      <li class="gl-flex gl-items-center gl-gap-3">
        <gl-link :href="assignedToYouPath">{{ __('Assigned to you') }}</gl-link>
        <template v-if="!isLoadingMetadata">
          <gl-badge data-testid="assigned-count">{{ assignedCount }}</gl-badge>
          <span
            v-if="assignedLastUpdatedAt"
            data-testid="assigned-last-updated-at"
            class="gl-ml-auto gl-text-subtle"
            >{{ timeFormatted(assignedLastUpdatedAt) }}</span
          >
        </template>
      </li>
    </ul>
  </div>
</template>
