<script>
import { GlIcon, GlLink, GlBadge, GlSprintf } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import mergeRequestsWidgetMetadataQuery from '../graphql/queries/merge_requests_widget_metadata.query.graphql';
import VisibilityChangeDetector from './visibility_change_detector.vue';

export default {
  name: 'MergeRequestsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
    GlSprintf,
    VisibilityChangeDetector,
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
  },
};
</script>

<template>
  <visibility-change-detector class="gl-border gl-rounded-lg gl-px-4 gl-py-1" @visible="reload">
    <h4 class="gl-heading-4 gl-my-4 gl-flex gl-items-center gl-gap-2">
      <gl-icon name="merge-request" :size="16" />{{ __('Merge requests') }}
    </h4>
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
    <ul v-else class="gl-list-none gl-p-0" data-testid="links-list">
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="reviewRequestedPath"
        >
          {{ __('Review requested') }}
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
        >
          {{ __('Assigned to you') }}
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
  </visibility-change-detector>
</template>
