<script>
import * as Sentry from '@sentry/browser';
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/dist/utils';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PANELS_WITH_PINS } from '../constants';
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

  i18n: {
    mainNavigation: s__('Navigation|Main navigation'),
  },

  data() {
    return {
      showFlyoutMenus: false,

      // This is used as a provide and injected into the nav items.
      // Note: It has to be an object to be reactive.
      changedPinnedItemIds: { ids: this.pinnedItemIds },
    };
  },

  computed: {
    // Returns the list of items that we want to have static at the top.
    // Only sidebars that support pins also support a static section.
    staticItems() {
      if (!this.supportsPins) return [];
      return this.items.filter((item) => !item.items || item.items.length === 0);
    },

    // Returns only the items that aren't static at the top and makes sure no
    // section shows as active (and expanded) when one of its items is pinned.
    nonStaticItems() {
      if (!this.supportsPins) return this.items;

      return this.items
        .filter((item) => item.items && item.items.length > 0)
        .map((item) => {
          const hasActivePinnedChild = item.items.some((childItem) => {
            return childItem.is_active && this.changedPinnedItemIds.ids.includes(childItem.id);
          });
          const showAsActive = item.is_active && !hasActivePinnedChild;

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
    supportsPins() {
      return this.isLoggedIn && PANELS_WITH_PINS.includes(this.panelType);
    },
    hasStaticItems() {
      return this.staticItems.length > 0;
    },
  },
  mounted() {
    if (this.glFeatures.superSidebarFlyoutMenus) {
      this.decideFlyoutState();
      window.addEventListener('resize', this.decideFlyoutState);
    }
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.decideFlyoutState);
  },
  methods: {
    createPin(itemId) {
      this.changedPinnedItemIds.ids.push(itemId);
      this.updatePins();
    },
    destroyPin(itemId) {
      this.changedPinnedItemIds.ids = this.changedPinnedItemIds.ids.filter((id) => id !== itemId);
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
  },
};
</script>

<template>
  <nav :aria-label="$options.i18n.mainNavigation" class="gl-p-2 gl-relative">
    <ul v-if="hasStaticItems" class="gl-p-0 gl-m-0" data-testid="static-items-section">
      <nav-item v-for="item in staticItems" :key="item.id" :item="item" is-static />
    </ul>
    <pinned-section
      v-if="supportsPins"
      separated
      :items="pinnedItems"
      :has-flyout="showFlyoutMenus"
      @pin-remove="destroyPin"
      @pin-reorder="movePin"
    />
    <hr
      v-if="supportsPins"
      aria-hidden="true"
      class="gl-my-2 gl-mx-4"
      data-testid="main-menu-separator"
    />
    <ul class="gl-p-0 gl-list-style-none" data-testid="non-static-items-section">
      <template v-for="item in nonStaticItems">
        <menu-section
          v-if="isSection(item)"
          :key="item.id"
          :item="item"
          :separated="item.separated"
          :has-flyout="showFlyoutMenus"
          @pin-add="createPin"
          @pin-remove="destroyPin"
        />
        <nav-item
          v-else
          :key="item.id"
          :item="item"
          tag="li"
          @pin-add="createPin"
          @pin-remove="destroyPin"
        />
      </template>
    </ul>
  </nav>
</template>
