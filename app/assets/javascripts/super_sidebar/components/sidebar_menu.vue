<script>
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/src/utils'; // eslint-disable-line no-restricted-syntax -- GlBreakpointInstance is used intentionally here. In this case we must obtain viewport breakpoints
import { GlNavItem, GlModalDirective, GlTooltipDirective, GlToastMixin } from '@gitlab/ui';
import superSidebarDataQuery from '~/super_sidebar/graphql/queries/super_sidebar.query.graphql';
import { __, s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { pinsPath } from '~/lib/utils/path_helpers/user';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, OPEN_FEATURE_LIBRARY } from '~/behaviors/shortcuts/keybindings';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { formatAsyncCount } from '~/super_sidebar/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import {
  PANEL_TYPES,
  PANELS_WITH_PINS,
  PINNED_NAV_STORAGE_KEY,
  MAX_OPEN_WORK_ITEMS_COUNT,
} from '../constants';
import NavItem from './nav_item.vue';
import PinnedSection from './pinned_section.vue';
import MenuSection from './menu_section.vue';
import FeatureLibraryModal from './feature_library/feature_library_modal.vue';
import { MODAL_ID, SHIMMER_CALLOUT_FEATURE_NAME } from './feature_library/constants';

export default {
  name: 'SidebarMenu',
  components: {
    MenuSection,
    NavItem,
    PinnedSection,
    GlNavItem,
    FeatureLibraryModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin(), GlToastMixin],
  modalId: MODAL_ID,
  i18n: {
    browseMoreFeatures: __('More features'),
    pinAdded: s__('Navigation|%{title} added to pinned items'),
    pinRemoved: s__('Navigation|%{title} removed from pinned items'),
  },
  inject: {
    currentPath: {},
    isIconOnly: { default: false },
  },
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
    showFeedbackLink: {
      type: Boolean,
      required: false,
      default: false,
    },
    showFeatureLibraryShimmer: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showFlyoutMenus: false,
      asyncCountQuery: {},

      // Tracks whether the "More features" shimmer should still play. Set to
      // false once the user opens the modal so the animation stops immediately
      // without waiting for a page reload; the dismissed callout keeps it off
      // on subsequent visits.
      shimmerActive: this.showFeatureLibraryShimmer,

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
      context: {
        featureCategory: 'navigation',
      },
      skip() {
        return !this.currentPath;
      },
      update(data) {
        const values = data?.namespace?.sidebar ?? {};
        const result = {};

        for (const [key, value] of Object.entries(values)) {
          if (key === 'openWorkItemsCount' && value >= MAX_OPEN_WORK_ITEMS_COUNT) {
            result[key] = `${formatAsyncCount(MAX_OPEN_WORK_ITEMS_COUNT)}+`;
          } else {
            const formatted = formatAsyncCount(value);
            if (formatted) {
              result[key] = formatted;
            }
          }
        }

        return result;
      },
      error(error) {
        // Override gon.feature_category as this code loads on all pages
        Sentry.captureException(error, { tags: { feature_category: 'navigation' } });
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
      if (this.panelType === PANEL_TYPES.YOUR_WORK) {
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
      if (!this.isPinnablePanel) return [];

      return this.items.filter((item) => !item.items || item.items.length === 0);
    },

    // Returns only the items that aren't static at the top and makes sure no
    // section shows as active (and expanded) when a pinned nav item was used.

    nonStaticItems() {
      if (!this.isPinnablePanel) return this.items;

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
      return this.changedPinnedItemIds.ids
        .map((id) => this.flatPinnableItems.find((item) => item.id === id))
        .filter(Boolean);
    },
    isPinnablePanel() {
      return PANELS_WITH_PINS.includes(this.panelType);
    },
    supportsPins() {
      return this.isLoggedIn && this.isPinnablePanel;
    },
    hasStaticItems() {
      return this.staticItems.length > 0;
    },
    showUnpinnedItems() {
      return (
        !this.glFeatures.hideUnpinnedSidebarItems ||
        !PANELS_WITH_PINS.filter((p) => p !== 'organization').includes(this.panelType)
      );
    },
    showFeatureLibrary() {
      return (
        this.isPinnablePanel &&
        this.panelType !== 'organization' &&
        (this.glFeatures.featureLibraryModal || !this.showUnpinnedItems)
      );
    },
    sectionsToRender() {
      if (!this.showUnpinnedItems) {
        return this.nonStaticItems.filter((item) => item.id === 'settings_menu');
      }
      return this.nonStaticItems;
    },
  },
  mounted() {
    this.decideFlyoutState();
    window.addEventListener('resize', this.decideFlyoutState);

    if (this.showFeatureLibrary) {
      Mousetrap.bind(keysFor(OPEN_FEATURE_LIBRARY), this.openFeatureLibrary);
    }
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.decideFlyoutState);

    if (this.showFeatureLibrary) {
      Mousetrap.unbind(keysFor(OPEN_FEATURE_LIBRARY));
    }
  },
  methods: {
    async dismissShimmerCallout() {
      // Guard so we only send the mutation the first time the modal is opened.
      if (!this.shimmerActive) return;

      this.shimmerActive = false;

      try {
        await this.$apollo.mutate({
          mutation: dismissUserCalloutMutation,
          variables: {
            input: { featureName: SHIMMER_CALLOUT_FEATURE_NAME },
          },
        });
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    openFeatureLibrary() {
      this.dismissShimmerCallout();
      this.$root.$emit(BV_SHOW_MODAL, MODAL_ID);

      return false;
    },
    createPin(itemId, itemTitle) {
      this.changedPinnedItemIds.ids.push(itemId);
      this.$toast.show(
        sprintf(this.$options.i18n.pinAdded, {
          title: itemTitle,
        }),
      );
      this.updatePins();
    },
    destroyPin(itemId, itemTitle, source = {}) {
      this.changedPinnedItemIds.ids = this.changedPinnedItemIds.ids.filter((id) => id !== itemId);
      this.$toast.show(
        sprintf(this.$options.i18n.pinRemoved, {
          title: itemTitle,
        }),
      );

      this.updatePins();

      if (source?.fromPinnedSection) {
        this.$nextTick(() => {
          this.$refs.pinnedSectionButton?.$el.querySelector('button')?.focus();
        });
      }
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
    onModalPinToggle(itemId, nextState, title) {
      const itemTitle = title || itemId;
      if (nextState) {
        this.createPin(itemId, itemTitle);
      } else {
        this.destroyPin(itemId, itemTitle);
      }
    },
    updatePins() {
      axios
        .put(pinsPath(), {
          panel: this.panelType,
          menu_item_ids: this.changedPinnedItemIds.ids,
        })
        .then((response) => {
          this.changedPinnedItemIds.ids = response.data;
        })
        .catch((e) => {
          // Override gon.feature_category as this code loads on all pages
          Sentry.captureException(e, { tags: { feature_category: 'navigation' } });
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
  <div
    class="gl-relative gl-px-3 gl-py-2"
    :class="{
      'gl-flex gl-h-full gl-flex-col': !showUnpinnedItems,
    }"
  >
    <ul
      v-if="hasStaticItems"
      class="gl-m-0 gl-list-none gl-p-0"
      :class="{ 'gl-mb-3': showUnpinnedItems }"
      data-testid="static-items-section"
    >
      <nav-item
        v-for="item in staticItems"
        :key="item.id"
        :item="item"
        is-static
        :async-count="asyncCount"
        class="gl-font-bold"
      />
    </ul>
    <pinned-section
      v-if="isPinnablePanel"
      id="super-sidebar-pinned-section"
      ref="pinnedSectionButton"
      :supports-pins="supportsPins"
      :items="pinnedItems"
      :has-flyout="showFlyoutMenus"
      :was-pinned-nav="wasPinnedNav"
      :headerless="!showUnpinnedItems"
      :async-count="asyncCount"
      @pin-remove="destroyPin"
      @pin-reorder="movePin"
    />
    <gl-nav-item
      v-if="showFeatureLibrary"
      v-gl-modal="$options.modalId"
      v-gl-tooltip.right.viewport="isIconOnly ? $options.i18n.browseMoreFeatures : ''"
      :aria-label="$options.i18n.browseMoreFeatures"
      :class="{ 'feature-library-shimmer': shimmerActive }"
      data-testid="feature-library-trigger"
      icon="applications"
      :is-icon-only="isIconOnly"
      @click="dismissShimmerCallout"
    >
      {{ $options.i18n.browseMoreFeatures }}
    </gl-nav-item>
    <feature-library-modal
      v-if="showFeatureLibrary"
      :supports-pins="supportsPins"
      :sections="nonStaticItems"
      :current-pinned-ids="changedPinnedItemIds.ids"
      :show-feedback-link="showFeedbackLink"
      @pin-toggle="onModalPinToggle"
    />
    <hr
      v-if="isPinnablePanel && showUnpinnedItems"
      aria-hidden="true"
      class="gl-mx-3 gl-my-4"
      data-testid="main-menu-separator"
    />
    <ul
      id="super-sidebar-non-static-section"
      aria-labelledby="super-sidebar-context-header"
      class="gl-mb-0 gl-list-none gl-p-0"
      :class="{
        'gl-mt-auto': !showUnpinnedItems,
      }"
      data-testid="non-static-items-section"
    >
      <template v-for="item in sectionsToRender">
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
