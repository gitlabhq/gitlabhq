<script>
import { s__ } from '~/locale';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import {
  PINNED_NAV_STORAGE_KEY,
  SIDEBAR_PINS_EXPANDED_COOKIE,
  SIDEBAR_COOKIE_EXPIRATION,
} from '../constants';
import { isPinnedGroupExpanded, setPinnedGroupExpanded } from '../utils';
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
    emptyHint: s__('Navigation|Pin frequently used features for quick access.'),
  },
  name: 'PinnedSection',
  components: {
    Draggable,
    MenuSection,
    NavItem,
  },
  inject: {
    isIconOnly: { default: false },
    panelType: { default: '' },
  },
  props: {
    supportsPins: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    headerless: {
      type: Boolean,
      required: false,
      default: false,
    },
    // When set, this section renders a category grouping of pinned items: the
    // category title as the header with no icon, and each pinned feature keeps
    // its own icon (unlike the flat "Pinned" section).
    groupItem: {
      type: Object,
      required: false,
      default: null,
    },
    asyncCount: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['pin-remove', 'pin-reorder'],
  data() {
    const storedExpanded = this.groupItem
      ? isPinnedGroupExpanded(this.pinnedGroupCollapseKey())
      : getCookie(SIDEBAR_PINS_EXPANDED_COOKIE) !== 'false';

    return {
      expanded: storedExpanded || this.wasPinnedNav,
      draggableItems: this.renameSettings(this.items),
    };
  },
  computed: {
    groupCollapseKey() {
      return this.pinnedGroupCollapseKey();
    },
    wrapperComponent() {
      return this.supportsPins ? Draggable : 'ul';
    },
    wrapperOptions() {
      if (!this.supportsPins) return {};

      return {
        value: this.draggableItems,
        itemKey: 'id',
        tag: 'ul',
        handle: '.js-draggable-icon',
        draggable: '.js-draggable-item',
      };
    },
    wrapperListeners() {
      if (!this.supportsPins) return {};

      return {
        input: this.updateDraggableItems,
        end: this.handleDrag,
      };
    },
    sectionItem() {
      if (this.groupItem) {
        return {
          // Category grouping: label the section with the category title and no
          // icon, so the feature icons on each pinned item stand out instead.
          title: this.groupItem.title,
          icon: null,
          // Like the flat section, only a pinned-nav click force-expands, so the
          // active category doesn't override the stored collapse state on reload.
          is_active: this.wasPinnedNav,
          items: this.draggableItems,
        };
      }

      return {
        title: this.$options.i18n.pinned,
        icon: 'thumbtack',
        is_active: this.wasPinnedNav,
        items: this.draggableItems,
      };
    },
  },
  watch: {
    expanded(newExpanded) {
      // Groups use local storage to avoid sending cookies the server never reads;
      // the flat section keeps its cookie to not change behavior outside the flag.
      if (this.groupItem) {
        setPinnedGroupExpanded(this.groupCollapseKey, newExpanded);
      } else {
        setCookie(SIDEBAR_PINS_EXPANDED_COOKIE, newExpanded, {
          expires: SIDEBAR_COOKIE_EXPIRATION,
        });
      }
    },
    items(newItems) {
      this.draggableItems = this.renameSettings(newItems);
    },
  },
  methods: {
    // Scoped by panel so the same category id stays independent across the
    // project and group sidebars. A method, not a computed, so data() can reuse it.
    pinnedGroupCollapseKey() {
      return this.groupItem ? `${this.panelType}-${this.groupItem.id}` : null;
    },
    updateDraggableItems(items) {
      this.draggableItems = items;
    },
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
      this.$emit('pin-remove', itemId, itemTitle, { fromPinnedSection: true });
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
    :headerless="headerless"
    :bold-title="Boolean(groupItem)"
    :async-count="asyncCount"
    @collapse-toggle="expanded = $event"
    @pin-remove="onPinRemove"
    @nav-link-click="writePinnedClick"
  >
    <component
      :is="wrapperComponent"
      v-if="items.length > 0"
      v-bind="wrapperOptions"
      class="gl-m-0 gl-list-none gl-p-0 gl-leading-normal"
      :aria-label="sectionItem.title"
      data-testid="pinned-nav-items"
      v-on="wrapperListeners"
    >
      <nav-item
        v-for="item of draggableItems"
        :key="item.id"
        :item="item"
        :async-count="asyncCount"
        :is-in-pinned-section="supportsPins"
        class="js-draggable-item"
        @pin-remove="onPinRemove(item.id, item.title)"
        @nav-link-click="writePinnedClick"
      />
    </component>
    <div
      v-else-if="!headerless && !isIconOnly"
      class="gl-ml-[2.25rem] gl-py-3 gl-text-sm gl-text-subtle"
    >
      {{ $options.i18n.emptyHint }}
    </div>
  </menu-section>
</template>
