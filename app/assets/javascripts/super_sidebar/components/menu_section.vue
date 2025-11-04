<script>
import { kebabCase } from 'lodash';
import {
  GlCollapse,
  GlIcon,
  GlAnimatedChevronRightDownIcon,
  GlOutsideDirective as Outside,
} from '@gitlab/ui';
import { NAV_ITEM_LINK_ACTIVE_CLASS } from '../constants';
import NavItem from './nav_item.vue';
import FlyoutMenu from './flyout_menu.vue';

export default {
  name: 'MenuSection',
  components: {
    GlCollapse,
    GlIcon,
    GlAnimatedChevronRightDownIcon,
    NavItem,
    FlyoutMenu,
  },
  directives: { Outside },
  inject: {
    isIconOnly: { default: false },
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    tag: {
      type: String,
      required: false,
      default: 'div',
    },
    hasFlyout: {
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
      isExpanded: Boolean(this.expanded || this.item.is_active),
      isMouseOverSection: false,
      isMouseOverFlyout: false,
      keepFlyoutClosed: false,
    };
  },
  computed: {
    navItems() {
      return this.item.items.filter((item) => {
        if (item.link_classes) {
          return !item.link_classes.includes('js-super-sidebar-nav-item-hidden');
        }
        return true;
      });
    },
    buttonProps() {
      return {
        'aria-controls': this.itemId,
        'aria-expanded': String(this.isExpanded),
        'data-qa-menu-item': this.item.title,
      };
    },
    computedLinkClasses() {
      return {
        [NAV_ITEM_LINK_ACTIVE_CLASS]: this.isActive,
        'with-mouse-over-flyout': this.isMouseOverFlyout,
      };
    },
    isActive() {
      return (!this.isExpanded || this.isIconOnly) && this.item.is_active;
    },
    itemId() {
      return kebabCase(this.item.title);
    },
    isMouseOver() {
      return this.isMouseOverSection || this.isMouseOverFlyout;
    },
    showExpanded() {
      return !this.isIconOnly && this.isExpanded;
    },
  },
  watch: {
    isExpanded(newIsExpanded) {
      this.$emit('collapse-toggle', newIsExpanded);
      this.keepFlyoutClosed = !this.newIsExpanded;
      if (!newIsExpanded) {
        this.isMouseOverFlyout = false;
      }
    },
  },
  methods: {
    handleClick() {
      if (this.isIconOnly) {
        this.isMouseOverSection = true; // Allows touch devices to open the flyout menus by touch
        return;
      }
      this.isExpanded = !this.isExpanded;
    },
    handleClickOutside() {
      this.isMouseOverSection = false; // Allows touch devices to close the flyout menus by touch
    },
    handlePointerover(e) {
      if (!this.hasFlyout) return;

      this.isMouseOverSection = e.pointerType === 'mouse' || e.pointerType === 'pen';
    },
    handlePointerleave(e) {
      if (!this.hasFlyout) return;

      this.keepFlyoutClosed = false;

      // delay state change. otherwise the flyout menu gets removed before it
      // has a chance to emit its mouseover event.
      // checks pointer type to not mess with touch devices, which fire a pointerleave event before
      // every click!
      if (e.pointerType === 'mouse' || e.pointerType === 'pen') {
        setTimeout(() => {
          this.isMouseOverSection = false;
        }, 5);
      }
    },
  },
};
</script>

<template>
  <component :is="tag">
    <button
      :id="`menu-section-button-${itemId}`"
      v-outside="handleClickOutside"
      class="super-sidebar-nav-item gl-relative gl-mb-1 gl-flex gl-w-full gl-appearance-none gl-items-center gl-gap-3 gl-rounded-base gl-border-0 gl-bg-transparent gl-p-2 gl-text-left gl-font-semibold !gl-text-default !gl-no-underline focus:gl-focus"
      :class="computedLinkClasses"
      data-testid="menu-section-button"
      :data-qa-section-name="item.title"
      :aria-label="item.title"
      v-bind="buttonProps"
      @click="handleClick"
      @pointerover="handlePointerover"
      @pointerleave="handlePointerleave"
    >
      <span class="gl-flex gl-h-6 gl-w-6 gl-shrink-0">
        <slot name="icon">
          <gl-icon
            v-if="item.icon"
            :name="item.icon"
            class="super-sidebar-nav-item-icon gl-m-auto"
          />
        </slot>
      </span>

      <span v-show="!isIconOnly" class="gl-truncate-end menu-section-button-label gl-grow">
        {{ item.title }}
      </span>

      <span v-if="!isIconOnly" class="gl-mr-2 gl-text-right gl-text-subtle">
        <gl-animated-chevron-right-down-icon :is-on="showExpanded" />
      </span>
    </button>

    <flyout-menu
      v-if="hasFlyout && isMouseOver && !showExpanded && !keepFlyoutClosed && navItems.length > 0"
      :target-id="`menu-section-button-${itemId}`"
      :title="item.title"
      :items="navItems"
      :async-count="asyncCount"
      @mouseover="isMouseOverFlyout = true"
      @mouseleave="isMouseOverFlyout = false"
      @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
      @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
      @nav-link-click="$emit('nav-link-click')"
    />

    <gl-collapse
      v-if="!isIconOnly"
      :id="itemId"
      v-model="isExpanded"
      class="gl-m-0 gl-list-none gl-p-0 gl-duration-medium gl-ease-ease"
      data-testid="menu-section"
      :data-qa-section-name="item.title"
    >
      <slot>
        <ul :aria-label="item.title" class="gl-m-0 gl-list-none gl-p-0">
          <nav-item
            v-for="subItem of navItems"
            :key="`${item.title}-${subItem.title}`"
            :item="subItem"
            :async-count="asyncCount"
            @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
            @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
          />
        </ul>
      </slot>
    </gl-collapse>
  </component>
</template>
