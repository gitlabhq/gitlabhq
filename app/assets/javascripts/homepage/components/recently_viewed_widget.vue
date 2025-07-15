<script>
import { GlButton, GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import RecentlyViewedItemsQuery from '../graphql/queries/recently_viewed_items.query.graphql';
import VisibilityChangeDetector from './visibility_change_detector.vue';

const MAX_ITEMS = 10;

export default {
  components: { GlButton, GlIcon, GlSkeletonLoader, VisibilityChangeDetector, TooltipOnTruncate },
  data() {
    return {
      items: [],
      error: null,
    };
  },
  apollo: {
    items: {
      query: RecentlyViewedItemsQuery,
      update({
        currentUser: { recentlyViewedIssues = [], recentlyViewedMergeRequests = [] } = {},
      }) {
        const enhanceWithIcon = (items, icon) => items.map((item) => ({ ...item, icon }));

        return [
          ...enhanceWithIcon(recentlyViewedIssues, 'issues'),
          ...enhanceWithIcon(recentlyViewedMergeRequests, 'merge-request'),
        ]
          .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
          .slice(0, MAX_ITEMS);
      },
      error(error) {
        Sentry.captureException(error);
        this.error = error;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.items.loading;
    },
  },
  methods: {
    reload() {
      this.error = null;
      this.$apollo.queries.items.refetch();
    },
  },
  MAX_ITEMS,
};
</script>

<template>
  <visibility-change-detector @visible="reload">
    <h4 class="gl-heading-4 gl-mb-4 gl-mt-0">{{ __('Recently viewed') }}</h4>

    <div v-if="error">
      <span>{{ __('Something went wrong.') }}</span>
      <gl-button size="small" @click="reload">{{ __('Try again') }}</gl-button>
    </div>
    <template v-else-if="isLoading">
      <gl-skeleton-loader v-for="i in $options.MAX_ITEMS" :key="i" :height="24">
        <rect x="0" y="0" width="16" height="16" rx="2" ry="2" />
        <rect x="24" y="0" width="200" height="16" rx="2" ry="2" />
      </gl-skeleton-loader>
    </template>

    <p v-else-if="!items.length">
      {{ __('Issues and merge requests you visit will appear here.') }}
    </p>
    <ul v-else class="gl-m-0 gl-flex gl-list-none gl-flex-col gl-gap-3 gl-p-0">
      <li v-for="item in items" :key="item.id">
        <a
          :href="item.webUrl"
          class="gl-flex gl-items-center gl-gap-2 gl-rounded-small gl-p-1 gl-text-default hover:gl-bg-subtle hover:gl-text-default hover:gl-no-underline"
        >
          <gl-icon :name="item.icon" class="gl-shrink-0" />
          <tooltip-on-truncate
            :title="item.title"
            class="gl-min-w-0 gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap"
          >
            {{ item.title }}
          </tooltip-on-truncate>
        </a>
      </li>
    </ul>
  </visibility-change-detector>
</template>
