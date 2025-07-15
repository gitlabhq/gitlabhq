<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import VisibilityChangeDetector from './visibility_change_detector.vue';

const MAX_EVENTS = 10;

export default {
  components: {
    GlAlert,
    GlSkeletonLoader,
    VisibilityChangeDetector,
  },
  directives: {
    SafeHtml,
  },
  data() {
    return {
      activityFeedHtml: null,
      isLoading: true,
      hasError: false,
    };
  },
  created() {
    this.reload();
  },
  methods: {
    async reload() {
      this.isLoading = true;

      try {
        /**
         * As part of this widget's first iteration, we have slightly changed how the `UsersController`
         * controller behaves so that it returns an empty response when the user has no activity and
         * the `is_personal_homepage` param is present. This is a temporary workaround until we can
         * move away from an HTML endpoint and handle empty states more gracefully in the client.
         * We'll need to remove the `is_personal_homepage` logic from `UsersController` once we have
         * a proper GraphQL endpoint here.
         */
        const { data } = await axios.get(
          `/users/${encodeURIComponent(gon.current_username)}/activity?limit=${MAX_EVENTS}&is_personal_homepage=1`,
        );
        this.activityFeedHtml = data?.html ?? null;
      } catch (e) {
        Sentry.captureException(e);
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <visibility-change-detector class="gl-px-4" @visible="reload">
    <h4 class="gl-heading-4 gl-my-4">{{ __('Activity') }}</h4>
    <gl-skeleton-loader v-if="isLoading" :width="200">
      <rect width="5" height="3" rx="1" y="2" />
      <rect width="160" height="3" rx="1" x="8" y="2" />
      <rect width="20" height="3" rx="1" x="180" y="2" />

      <rect width="5" height="3" rx="1" y="9" />
      <rect width="160" height="3" rx="1" x="8" y="9" />
      <rect width="20" height="3" rx="1" x="180" y="9" />

      <rect width="5" height="3" rx="1" y="16" />
      <rect width="160" height="3" rx="1" x="8" y="16" />
      <rect width="20" height="3" rx="1" x="180" y="16" />
    </gl-skeleton-loader>
    <gl-alert v-else-if="hasError" variant="danger">{{
      s__(
        'HomepageActivityWidget|The activity feed is not available. Please refresh the page to try again.',
      )
    }}</gl-alert>
    <p v-else-if="!activityFeedHtml" data-testid="empty-state">
      {{
        s__(
          'Homepage|Start creating merge requests, pushing code, commenting in issues, and doing other work to view a feed of your activity here.',
        )
      }}
    </p>
    <ul
      v-else
      v-safe-html="activityFeedHtml"
      data-testid="events-list"
      class="gl-list-none gl-p-0"
    ></ul>
  </visibility-change-detector>
</template>
