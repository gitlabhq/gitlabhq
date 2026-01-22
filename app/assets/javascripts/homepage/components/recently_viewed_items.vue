<script>
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import RecentlyViewedItemsQuery from 'ee_else_ce/homepage/graphql/queries/recently_viewed_items.query.graphql';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_RECENTLY_VIEWED,
} from '../tracking_constants';

const MAX_ITEMS = 10;

export default {
  name: 'RecentlyViewedItems',
  components: {
    GlIcon,
    GlSkeletonLoader,
    TooltipOnTruncate,
  },
  mixins: [InternalEvents.mixin()],
  data() {
    return {
      items: [],
      error: null,
    };
  },
  apollo: {
    items: {
      query: RecentlyViewedItemsQuery,
      update({ currentUser: { recentlyViewedItems = [] } = {} }) {
        return recentlyViewedItems
          .map((entry) => ({
            ...entry.item,
            viewedAt: entry.viewedAt,
            itemType: entry.itemType,
            // eslint-disable-next-line no-underscore-dangle
            icon: this.getIconForItemType(entry.item.__typename),
          }))
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
    emptyStateMessage() {
      return __('Issues and merge requests you visit will appear here.');
    },
  },
  methods: {
    reload() {
      this.error = null;
      this.$apollo.queries.items.refetch();
    },
    getIconForItemType(itemType) {
      const iconMap = {
        Issue: 'work-item-issue',
        MergeRequest: 'merge-request',
        Epic: 'work-item-epic',
      };
      return iconMap[itemType] || 'question';
    },
    handleItemClick(item) {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_RECENTLY_VIEWED,
        // eslint-disable-next-line no-underscore-dangle
        property: item.__typename,
      });
    },
  },
  MAX_ITEMS,
};
</script>

<template>
  <div data-testid="homepage-quick-access-widget" @visible="reload">
    <p v-if="error" class="gl-mb-0">
      {{
        s__(
          'HomePageRecentlyViewedWidget|Your recently viewed items are not available. Please refresh the page to try again.',
        )
      }}
    </p>

    <template v-else-if="isLoading">
      <div class="gl-flex gl-flex-col gl-gap-y-4 gl-pt-3">
        <gl-skeleton-loader
          v-for="i in $options.MAX_ITEMS"
          :key="i"
          :lines="1"
          :equal-width-lines="true"
        />
      </div>
    </template>

    <p v-else-if="!items.length" class="gl-my-0 gl-mb-3">
      {{ emptyStateMessage }}
    </p>
    <ul v-else class="gl-m-0 gl-list-none gl-p-0">
      <li v-for="item in items" :key="item.id">
        <a
          :href="item.webUrl"
          class="-gl-mx-3 gl-flex gl-items-center gl-gap-2 gl-rounded-base gl-p-3 gl-text-default hover:gl-bg-subtle hover:gl-text-default hover:gl-no-underline"
          @click="handleItemClick(item)"
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
  </div>
</template>
