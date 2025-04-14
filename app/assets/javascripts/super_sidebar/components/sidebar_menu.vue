<script>
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/dist/utils';
import { uniqBy } from 'lodash';
import superSidebarDataQuery from '~/super_sidebar/graphql/queries/super_sidebar.query.graphql';
import { s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { formatAsyncCount } from '~/super_sidebar/utils';
import { PANELS_WITH_PINS, PINNED_NAV_STORAGE_KEY } from '../constants';
import NavItem from './nav_item.vue';
import PinnedSection from './pinned_section.vue';
import MenuSection from './menu_section.vue';

export default {
  name: 'SidebarMenu',
  components: {
    MenuSection,
    NavItem,
    PinnedSection,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    pinAdded: s__('Navigation|%{title} added to pinned items'),
    pinRemoved: s__('Navigation|%{title} removed from pinned items'),
  },
  inject: ['currentPath'],
  provide() {
    return {
      pinnedItemIds: this.changedPinnedItemIds,
      panelSupportsPins: this.supportsPins,
      panelType: this.panelType,
    };
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    isLoggedIn: {
      type: Boolean,
      required: true,
    },
    pinnedItemIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    panelType: {
      type: String,
      required: false,
      default: '',
    },
    updatePinsUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showFlyoutMenus: false,
      asyncCountQuery: {},

      // This is used to detect if user came to this page by clicking a
      // nav item in the pinned section.
      wasPinnedNav: this.readAndResetPinnedNav(),

      // This is used as a provide and injected into the nav items.
      // Note: It has to be an object to be reactive.
      changedPinnedItemIds: { ids: this.pinnedItemIds },
    };
  },
  apollo: {
    asyncCountQuery: {
      query: superSidebarDataQuery,
      variables() {
        return { fullPath: this.currentPath };
      },
      skip() {
        return !this.currentPath;
      },
      update(data) {
        const values = data?.namespace?.sidebar ?? {};
        const result = {};

        for (const [key, value] of Object.entries(values)) {
          const formatted = formatAsyncCount(value);
          if (formatted) {
            result[key] = formatted;
          }
        }

        return result;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    /**
     * The behaviour below might be a little unintuitive. For some sidebar items we have set `pill_count_field`
     * instead of `pill_count`. This is used for work item counts on groups and projects, so that they happen
     * async with the asyncCountQuery above.
     *
     * For the `Your work` sidebar we are using the userCounts from user_counts_manager.js, to make sure that
     * the counts always match what is in the UserBar.
     *
     * It is thinkable that we move all of this out into a "Count Manager" and use it in all sidebars, so that
     * the sidebar can become a little more agnostic regarding the logic of counts. The sidebar would just ask:
     * Yo, Count Manager, what is the count for this item and retrieve it. Whether that data available sync,
     * via a Service Worker or some GraphQL API calls, shouldn't matter too much.
     */
    asyncCount() {
      if (this.panelType === 'your_work') {
        const result = {};
        for (const [key, value] of Object.entries(userCounts)) {
          result[key] = value > 0 ? value : null;
        }
        return result;
      }
      return this.asyncCountQuery;
    },
    // Returns the list of items that we want to have static at the top.
    // Only sidebars that support pins also support a static section.
    staticItems() {
      if (!this.supportsPins) return [];
      return this.items.filter((item) => !item.items || item.items.length === 0);
    },

    // Returns only the items that aren't static at the top and makes sure no
    // section shows as active (and expanded) when a pinned nav item was used.

    nonStaticItems() {
      if (!this.supportsPins) return this.items;

      return this.items
        .filter((item) => item.items && item.items.length > 0)
        .map((item) => {
          const showAsActive = item.is_active && !this.wasPinnedNav;

          return { ...item, is_active: showAsActive };
        });
    },

    // Returns a flat list of all items that are in sections, but not the sections.
    // Only items from sections (item.items) can be pinned.
    flatPinnableItems() {
      return this.nonStaticItems.flatMap((item) => item.items).filter(Boolean);
    },

    pinnedItems() {
      const baseItems = this.changedPinnedItemIds.ids
        .map((id) => this.flatPinnableItems.find((item) => item.id === id))
        .filter(Boolean);

      // Deduplicate Work items pinned items during migration from Issues + Epics
      return uniqBy(baseItems, (item) => item.title);
    },
    supportsPins() {
      return this.isLoggedIn && PANELS_WITH_PINS.includes(this.panelType);
    },
    hasStaticItems() {
      return this.staticItems.length > 0;
    },
  },
  mounted() {
    this.decideFlyoutState();
    window.addEventListener('resize', this.decideFlyoutState);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.decideFlyoutState);
  },
  methods: {
    createPin(itemId, itemTitle) {
      this.changedPinnedItemIds.ids.push(itemId);
      this.$toast.show(
        sprintf(this.$options.i18n.pinAdded, {
          title: itemTitle,
        }),
      );
      this.updatePins();
    },
    destroyPin(itemId, itemTitle) {
      this.changedPinnedItemIds.ids = this.changedPinnedItemIds.ids.filter((id) => id !== itemId);
      this.$toast.show(
        sprintf(this.$options.i18n.pinRemoved, {
          title: itemTitle,
        }),
      );
      this.updatePins();
    },
    movePin(fromId, toId, isDownwards) {
      const fromIndex = this.changedPinnedItemIds.ids.indexOf(fromId);
      this.changedPinnedItemIds.ids.splice(fromIndex, 1);

      let toIndex = this.changedPinnedItemIds.ids.indexOf(toId);

      // If the item was moved downwards, we insert it *after* the item it was dragged on to.
      // This matches how vuedraggable previews the change while still dragging.
      if (isDownwards) toIndex += 1;

      this.changedPinnedItemIds.ids.splice(toIndex, 0, fromId);

      this.updatePins();
    },
    updatePins() {
      axios
        .put(this.updatePinsUrl, {
          panel: this.panelType,
          menu_item_ids: this.changedPinnedItemIds.ids,
        })
        .then((response) => {
          this.changedPinnedItemIds.ids = response.data;
        })
        .catch((e) => {
          Sentry.captureException(e);
        });
    },
    isSection(navItem) {
      return navItem.items?.length;
    },
    decideFlyoutState() {
      this.showFlyoutMenus = GlBreakpointInstance.windowWidth() >= breakpoints.md;
    },
    readAndResetPinnedNav() {
      const wasPinnedNav = sessionStorage.getItem(PINNED_NAV_STORAGE_KEY);
      sessionStorage.removeItem(PINNED_NAV_STORAGE_KEY);
      return wasPinnedNav === 'true';
    },
  },
};
</script>

<template>
  <div class="gl-relative gl-p-2">
    <ul v-if="hasStaticItems" class="gl-m-0 gl-list-none gl-p-0" data-testid="static-items-section">
      <nav-item
        v-for="item in staticItems"
        :key="item.id"
        :item="item"
        is-static
        :async-count="asyncCount"
      />
    </ul>
    <pinned-section
      v-if="supportsPins"
      :items="pinnedItems"
      :has-flyout="showFlyoutMenus"
      :was-pinned-nav="wasPinnedNav"
      :async-count="asyncCount"
      @pin-remove="destroyPin"
      @pin-reorder="movePin"
    />
    <hr
      v-if="supportsPins"
      aria-hidden="true"
      class="gl-mx-4 gl-my-2"
      data-testid="main-menu-separator"
    />
    <ul
      aria-labelledby="super-sidebar-context-header"
      class="gl-mb-0 gl-list-none gl-p-0"
      data-testid="non-static-items-section"
    >
      <template v-for="item in nonStaticItems">
        <menu-section
          v-if="isSection(item)"
          :key="item.id"
          :item="item"
          :separated="item.separated"
          :has-flyout="showFlyoutMenus"
          :async-count="asyncCount"
          tag="li"
          @pin-add="createPin"
          @pin-remove="destroyPin"
        />
        <nav-item
          v-else
          :key="item.id"
          :item="item"
          :async-count="asyncCount"
          @pin-add="createPin"
          @pin-remove="destroyPin"
        />
      </template>
    </ul>
  </div>
</template>
