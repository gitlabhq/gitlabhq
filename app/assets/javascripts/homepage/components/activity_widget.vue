<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';

const MAX_EVENTS = 10;

export default {
  components: {
    GlAlert,
    GlSkeletonLoader,
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
  async created() {
    try {
      const { data } = await axios.get(
        `/users/${encodeURIComponent(gon.current_username)}/activity?limit=${MAX_EVENTS}`,
      );
      this.activityFeedHtml = data.html;
    } catch (e) {
      Sentry.captureException(e);
      this.hasError = true;
    } finally {
      this.isLoading = false;
    }
  },
};
</script>

<template>
  <div>
    <h4>{{ __('Activity') }}</h4>
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
    <ul
      v-else
      v-safe-html="activityFeedHtml"
      data-testid="events-list"
      class="gl-list-none gl-p-0"
    ></ul>
  </div>
</template>
