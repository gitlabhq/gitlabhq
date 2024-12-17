<script>
import Draggable from 'vuedraggable';
import { s__ } from '~/locale';
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import {
  PINNED_NAV_STORAGE_KEY,
  SIDEBAR_PINS_EXPANDED_COOKIE,
  SIDEBAR_COOKIE_EXPIRATION,
} from '../constants';
import MenuSection from './menu_section.vue';
import NavItem from './nav_item.vue';

const AMBIGUOUS_SETTINGS = {
  ci_cd: s__('Navigation|CI/CD settings'),
  merge_request_settings: s__('Navigation|Merge requests settings'),
  monitor: s__('Navigation|Monitor settings'),
  repository: s__('Navigation|Repository settings'),
};

export default {
  i18n: {
    pinned: s__('Navigation|Pinned'),
    emptyHint: s__('Navigation|Your pinned items appear here.'),
  },
  name: 'PinnedSection',
  components: {
    Draggable,
    MenuSection,
    NavItem,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    hasFlyout: {
      type: Boolean,
      required: false,
      default: false,
    },
    wasPinnedNav: {
      type: Boolean,
      required: false,
      default: false,
    },
    asyncCount: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      expanded: getCookie(SIDEBAR_PINS_EXPANDED_COOKIE) !== 'false' || this.wasPinnedNav,
      draggableItems: this.renameSettings(this.items),
    };
  },
  computed: {
    sectionItem() {
      return {
        title: this.$options.i18n.pinned,
        icon: 'thumbtack',
        is_active: this.wasPinnedNav,
        items: this.draggableItems,
      };
    },
    itemIds() {
      return this.draggableItems.map((item) => item.id);
    },
  },
  watch: {
    expanded(newExpanded) {
      setCookie(SIDEBAR_PINS_EXPANDED_COOKIE, newExpanded, {
        expires: SIDEBAR_COOKIE_EXPIRATION,
      });
    },
    items(newItems) {
      this.draggableItems = this.renameSettings(newItems);
    },
  },
  methods: {
    handleDrag(event) {
      if (event.oldIndex === event.newIndex) return;
      this.$emit(
        'pin-reorder',
        this.items[event.oldIndex].id,
        this.items[event.newIndex].id,
        event.oldIndex < event.newIndex,
      );
    },
    renameSettings(items) {
      return items.map((i) => {
        const title = AMBIGUOUS_SETTINGS[i.id] || i.title;
        return { ...i, title };
      });
    },
    onPinRemove(itemId, itemTitle) {
      this.$emit('pin-remove', itemId, itemTitle);
    },
    writePinnedClick() {
      sessionStorage.setItem(PINNED_NAV_STORAGE_KEY, true);
    },
  },
};
</script>

<template>
  <menu-section
    :item="sectionItem"
    :expanded="expanded"
    :has-flyout="hasFlyout"
    @collapse-toggle="expanded = !expanded"
    @pin-remove="onPinRemove"
    @nav-link-click="writePinnedClick"
  >
    <draggable
      v-if="items.length > 0"
      v-model="draggableItems"
      class="gl-m-0 gl-list-none gl-p-0"
      data-testid="pinned-nav-items"
      handle=".js-draggable-icon"
      tag="ul"
      @end="handleDrag"
    >
      <nav-item
        v-for="item of draggableItems"
        :key="item.id"
        :item="item"
        :async-count="asyncCount"
        is-in-pinned-section
        @pin-remove="onPinRemove(item.id, item.title)"
        @nav-link-click="writePinnedClick"
      />
    </draggable>
    <li v-else class="gl-py-3 gl-text-sm gl-text-subtle" style="margin-left: 2.5rem">
      {{ $options.i18n.emptyHint }}
    </li>
  </menu-section>
</template>
