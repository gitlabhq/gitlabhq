<script>
import Draggable from 'vuedraggable';
import { s__ } from '~/locale';
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import { SIDEBAR_PINS_EXPANDED_COOKIE, SIDEBAR_COOKIE_EXPIRATION } from '../constants';
import MenuSection from './menu_section.vue';
import NavItem from './nav_item.vue';

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
  },
  data() {
    return {
      expanded: getCookie(SIDEBAR_PINS_EXPANDED_COOKIE) !== 'false',
      draggableItems: this.items,
    };
  },
  computed: {
    isActive() {
      return this.items.some((item) => item.is_active);
    },
    sectionItem() {
      return { title: this.$options.i18n.pinned, icon: 'thumbtack', is_active: this.isActive };
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
      this.draggableItems = newItems;
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
  },
};
</script>

<template>
  <menu-section
    :item="sectionItem"
    :expanded="expanded"
    :separated="true"
    collection-style
    @collapse-toggle="expanded = !expanded"
  >
    <draggable
      v-if="items.length > 0"
      v-model="draggableItems"
      class="gl-p-0 gl-m-0"
      data-testid="pinned-nav-items"
      handle=".draggable-icon"
      tag="ul"
      @end="handleDrag"
    >
      <nav-item
        v-for="item of draggableItems"
        :key="item.id"
        :item="item"
        is-in-pinned-section
        @pin-remove="(itemId) => $emit('pin-remove', itemId)"
      />
    </draggable>
    <li v-else class="gl-text-secondary gl-font-sm gl-py-3" style="margin-left: 2.5rem">
      {{ $options.i18n.emptyHint }}
    </li>
  </menu-section>
</template>
