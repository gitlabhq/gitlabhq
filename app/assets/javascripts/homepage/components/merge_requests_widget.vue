<script>
import { GlIcon, GlLink, GlBadge, GlSprintf } from '@gitlab/ui';
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
import BaseWidget from './base_widget.vue';

export default {
  name: 'MergeRequestsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
    GlSprintf,
    BaseWidget,
  },
  mixins: [timeagoMixin, InternalEvents.mixin()],
  inject: [
    'duoCodeReviewBotUsername',
    'mergeRequestsReviewRequestedTitle',
    'mergeRequestsYourMergeRequestsTitle',
  ],

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
      return this.metadata.reviewRequestedMergeRequests?.count ?? '-';
    },
    reviewRequestedLastUpdatedAt() {
      return this.metadata?.reviewRequestedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
    assignedCount() {
      return this.metadata.assignedMergeRequests?.count ?? '-';
    },
    assignedLastUpdatedAt() {
      return this.metadata?.assignedMergeRequests?.nodes?.[0]?.updatedAt ?? null;
    },
  },
  methods: {
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
  },
};
</script>

<template>
  <base-widget @visible="reload">
    <h2 class="gl-heading-4 gl-mb-4 gl-mt-1 gl-flex gl-items-center gl-gap-2">
      <gl-icon name="merge-request" :size="16" />{{ __('Merge requests') }}
    </h2>
    <p v-if="hasError" data-testid="error-message">
      <gl-sprintf
        :message="
          s__(
            'HomePageMergeRequestsWidget|The number of merge requests is not available. Please refresh the page to try again, or visit the %{linkStart}dashboard%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="assignedToYouPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <ul v-else class="gl-mb-1 gl-list-none gl-p-0" data-testid="links-list">
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="reviewRequestedPath"
          @click="handleReviewRequestedClick"
        >
          {{ mergeRequestsReviewRequestedTitle }}
          <gl-badge data-testid="review-requested-count">{{ reviewRequestedCount }}</gl-badge>
          <span
            v-if="reviewRequestedLastUpdatedAt"
            data-testid="review-requested-last-updated-at"
            class="gl-ml-auto gl-text-sm gl-text-subtle"
            >{{ timeFormatted(reviewRequestedLastUpdatedAt) }}</span
          >
        </gl-link>
      </li>
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="assignedToYouPath"
          @click="handleAssignedClick"
        >
          {{ mergeRequestsYourMergeRequestsTitle }}
          <gl-badge data-testid="assigned-count">{{ assignedCount }}</gl-badge>
          <span
            v-if="assignedLastUpdatedAt"
            data-testid="assigned-last-updated-at"
            class="gl-ml-auto gl-text-sm gl-text-subtle"
            >{{ timeFormatted(assignedLastUpdatedAt) }}</span
          >
        </gl-link>
      </li>
    </ul>
  </base-widget>
</template>
