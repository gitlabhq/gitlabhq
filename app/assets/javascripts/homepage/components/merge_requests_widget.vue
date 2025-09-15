<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import mergeRequestsWidgetMetadataQuery from '../graphql/queries/merge_requests_widget_metadata.query.graphql';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_MERGE_REQUESTS,
  TRACKING_PROPERTY_REVIEW_REQUESTED,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
} from '../tracking_constants';

export default {
  name: 'MergeRequestsWidget',
  components: {
    GlIcon,
    GlLink,
  },
  mixins: [timeagoMixin, InternalEvents.mixin()],
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
      hasError: false,
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
        this.hasError = true;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    reviewRequestedCount() {
      const count = this.metadata.reviewRequestedMergeRequests?.count;
      return count != null ? this.formatCount(count) : '-';
    },
    reviewRequestedLastUpdatedAt() {
      return this.metadata?.reviewRequestedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
    assignedCount() {
      const count = this.metadata.assignedMergeRequests?.count;
      return count != null ? this.formatCount(count) : '-';
    },
    assignedLastUpdatedAt() {
      return this.metadata?.assignedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
  },
  mounted() {
    document.addEventListener('visibilitychange', this.handleVisibilityChanged);
  },
  beforeDestroy() {
    document.removeEventListener('visibilitychange', this.handleVisibilityChanged);
  },
  methods: {
    formatCount(count) {
      if (Math.abs(count) < 10000) {
        return new Intl.NumberFormat(navigator.language, {
          useGrouping: false,
        }).format(count);
      }
      return new Intl.NumberFormat(navigator.language, {
        notation: 'compact',
        compactDisplay: 'short',
        maximumFractionDigits: 1,
      }).format(count);
    },
    reload() {
      this.hasError = false;
      this.$apollo.queries.metadata.refetch();
    },
    handleReviewRequestedClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_MERGE_REQUESTS,
        property: TRACKING_PROPERTY_REVIEW_REQUESTED,
      });
    },
    handleAssignedClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_MERGE_REQUESTS,
        property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
      });
    },
    handleVisibilityChanged() {
      if (!document.hidden) {
        this.reload();
      }
    },
  },
};
</script>

<template>
  <div class="gl-grid gl-grid-cols-2 gl-gap-5">
    <gl-link
      class="gl-border gl-flex-1 gl-cursor-pointer gl-rounded-lg gl-border-subtle gl-bg-subtle gl-px-4 gl-py-4 hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
      :href="reviewRequestedPath"
      :aria-label="s__('HomePageMergeRequestsWidget|Merge requests with review requested')"
      variant="meta"
      @click="handleReviewRequestedClick"
    >
      <div>
        <div v-if="hasError" class="gl-m-2">
          <div class="gl-flex gl-flex-col gl-items-start gl-gap-4">
            <gl-icon name="error" class="gl-text-red-500" :size="16" />
            <p class="gl-text-size-h5 gl-text-default-400 gl-mb-0">
              {{
                s__(
                  'HomePageMergeRequestsWidget|The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.',
                )
              }}
            </p>
          </div>
        </div>
        <div v-else>
          <div class="gl-m-2 gl-flex gl-items-center gl-gap-4">
            <div class="gl-heading-1 gl-mb-0" data-testid="review-requested-count">
              {{ reviewRequestedCount }}
            </div>
            <gl-icon name="merge-request" :size="16" />
          </div>
          <h2 class="gl-heading-5 gl-mb-0 gl-font-normal">
            {{ s__('HomePageMergeRequestsWidget|Merge requests waiting for your review') }}
          </h2>
          <span
            v-if="reviewRequestedLastUpdatedAt"
            data-testid="review-requested-last-updated-at"
            class="gl-text-sm gl-text-gray-400 gl-text-subtle"
          >
            {{ timeFormatted(reviewRequestedLastUpdatedAt) }}
          </span>
        </div>
      </div>
    </gl-link>
    <gl-link
      class="gl-border gl-flex-1 gl-cursor-pointer gl-rounded-lg gl-border-subtle gl-bg-subtle gl-px-4 gl-py-4 hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
      :href="assignedToYouPath"
      :aria-label="s__('HomePageMergeRequestsWidget|Merge requests assigned to you')"
      data-testid="assigned-to-you-card"
      variant="meta"
      @click="handleAssignedClick"
    >
      <div>
        <div v-if="hasError" class="gl-m-2">
          <div class="gl-flex gl-flex-col gl-items-start gl-gap-4">
            <gl-icon name="error" class="gl-text-red-500" :size="16" />
            <p class="gl-text-size-h3 gl-text-default-400 gl-mb-0">
              {{
                s__(
                  'HomePageMergeRequestsWidget|The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.',
                )
              }}
            </p>
          </div>
        </div>
        <div v-else>
          <div class="gl-m-2 gl-flex gl-items-center gl-gap-4">
            <div class="gl-heading-1 gl-mb-0" data-testid="assigned-count">
              {{ assignedCount }}
            </div>
            <gl-icon name="merge-request" :size="16" />
          </div>
          <h2 class="gl-heading-5 gl-mb-0 gl-font-normal">
            {{ s__('HomePageMergeRequestsWidget|Merge requests assigned to you') }}
          </h2>
          <span
            v-if="assignedLastUpdatedAt"
            data-testid="assigned-last-updated-at"
            class="gl-text-sm gl-text-gray-400 gl-text-subtle"
          >
            {{ timeFormatted(assignedLastUpdatedAt) }}
          </span>
        </div>
      </div>
    </gl-link>
  </div>
</template>
