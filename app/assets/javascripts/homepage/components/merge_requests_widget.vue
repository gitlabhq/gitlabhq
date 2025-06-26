<script>
import { GlIcon, GlLink, GlBadge } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { createAlert, VARIANT_WARNING } from '~/alert';
import { __ } from '~/locale';
import mergeRequestsWidgetMetadataQuery from '../graphql/queries/merge_requests_widget_metadata.query.graphql';

export default {
  name: 'MergeRequestsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
  },
  mixins: [timeagoMixin],
  inject: ['duoCodeReviewBotUsername'],
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
      hasFetchError: false,
    };
  },
  apollo: {
    metadata: {
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
        this.hasFetchError = true;
        createAlert({
          title: __('Number of merge requests not available'),
          message: __(
            'The number of merge requests is not available. Please refresh the page to try again.',
          ),
          variant: VARIANT_WARNING,
          error,
        });
      },
    },
  },
  computed: {
    isLoadingMetadata() {
      return this.$apollo.queries.metadata.loading;
    },
    reviewRequestedCount() {
      if (
        this.isLoadingMetadata ||
        this.hasFetchError ||
        this.metadata.reviewRequestedMergeRequests?.count === undefined
      )
        return '-';
      return this.metadata.reviewRequestedMergeRequests.count;
    },
    reviewRequestedLastUpdatedAt() {
      return this.metadata?.reviewRequestedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
    assignedCount() {
      if (
        this.isLoadingMetadata ||
        this.hasFetchError ||
        this.metadata.assignedMergeRequests?.count === undefined
      )
        return '-';
      return this.metadata.assignedMergeRequests.count;
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
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="reviewRequestedPath"
        >
          {{ __('Review requested') }}
          <gl-badge data-testid="review-requested-count">{{ reviewRequestedCount }}</gl-badge>
          <template v-if="!isLoadingMetadata">
            <span
              v-if="reviewRequestedLastUpdatedAt"
              data-testid="review-requested-last-updated-at"
              class="gl-ml-auto gl-text-subtle"
              >{{ timeFormatted(reviewRequestedLastUpdatedAt) }}</span
            >
          </template>
        </gl-link>
      </li>
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="assignedToYouPath"
        >
          {{ __('Assigned to you') }}
          <gl-badge data-testid="assigned-count">{{ assignedCount }}</gl-badge>
          <template v-if="!isLoadingMetadata">
            <span
              v-if="assignedLastUpdatedAt"
              data-testid="assigned-last-updated-at"
              class="gl-ml-auto gl-text-subtle"
              >{{ timeFormatted(assignedLastUpdatedAt) }}</span
            >
          </template>
        </gl-link>
      </li>
    </ul>
  </div>
</template>
