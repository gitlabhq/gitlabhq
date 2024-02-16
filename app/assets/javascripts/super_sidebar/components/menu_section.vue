<script>
import { kebabCase } from 'lodash';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import { NAV_ITEM_LINK_ACTIVE_CLASS } from '../constants';
import NavItem from './nav_item.vue';
import FlyoutMenu from './flyout_menu.vue';

export default {
  name: 'MenuSection',
  components: {
    GlCollapse,
    GlIcon,
    NavItem,
    FlyoutMenu,
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
    separated: {
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
    buttonProps() {
      return {
        'aria-controls': this.itemId,
        'aria-expanded': String(this.isExpanded),
        'data-qa-menu-item': this.item.title,
      };
    },
    collapseIcon() {
      if (this.hasFlyout) {
        return this.isExpanded ? 'chevron-down' : 'chevron-right';
      }
      return this.isExpanded ? 'chevron-up' : 'chevron-down';
    },
    computedLinkClasses() {
      return this.isActive ? NAV_ITEM_LINK_ACTIVE_CLASS : null;
    },
    isActive() {
      return !this.isExpanded && this.item.is_active;
    },
    itemId() {
      return kebabCase(this.item.title);
    },
    isMouseOver() {
      return this.isMouseOverSection || this.isMouseOverFlyout;
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
    handlePointerover(e) {
      if (!this.hasFlyout) return;

      this.isMouseOverSection = e.pointerType === 'mouse';
    },
    handlePointerleave() {
      if (!this.hasFlyout) return;

      this.keepFlyoutClosed = false;
      // delay state change. otherwise the flyout menu gets removed before it
      // has a chance to emit its mouseover event.
      setTimeout(() => {
        this.isMouseOverSection = false;
      }, 5);
    },
  },
};
</script>

<template>
  <component :is="tag">
    <hr v-if="separated" aria-hidden="true" class="gl-mx-4 gl-my-2" />
    <button
      :id="`menu-section-button-${itemId}`"
      class="super-sidebar-nav-item gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-min-h-7 gl-gap-3 gl-mb-2 gl-py-2 gl-px-3 gl-text-black-normal! gl-text-decoration-none! gl-appearance-none gl-border-0 gl-bg-transparent gl-text-left gl-w-full gl-focus--focus"
      :class="computedLinkClasses"
      data-testid="menu-section-button"
      :data-qa-section-name="item.title"
      v-bind="buttonProps"
      @click="isExpanded = !isExpanded"
      @pointerover="handlePointerover"
      @pointerleave="handlePointerleave"
    >
      <span
        :class="[isActive ? 'active-indicator gl-bg-blue-500' : 'gl-bg-transparent']"
        class="gl-absolute gl-left-2 gl-top-2 gl-bottom-2 gl-transition-slow"
        aria-hidden="true"
        style="width: 3px; border-radius: 3px; margin-right: 1px"
      ></span>
      <span class="gl-flex-shrink-0 gl-w-6 gl-display-flex">
        <slot name="icon">
          <gl-icon
            v-if="item.icon"
            :name="item.icon"
            class="super-sidebar-nav-item-icon gl-m-auto"
          />
        </slot>
      </span>

      <span class="gl-flex-grow-1 gl-text-gray-900 gl-truncate-end">
        {{ item.title }}
      </span>

      <span class="gl-text-right gl-text-gray-400">
        <gl-icon class="super-sidebar-mix-blend-mode" :name="collapseIcon" />
      </span>
    </button>

    <flyout-menu
      v-if="hasFlyout && isMouseOver && !isExpanded && !keepFlyoutClosed && item.items.length > 0"
      :target-id="`menu-section-button-${itemId}`"
      :items="item.items"
      @mouseover="isMouseOverFlyout = true"
      @mouseleave="isMouseOverFlyout = false"
      @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
      @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
      @nav-link-click="$emit('nav-link-click')"
    />

    <gl-collapse
      :id="itemId"
      v-model="isExpanded"
      class="gl-list-style-none gl-p-0 gl-m-0 gl-transition-duration-medium gl-transition-timing-function-ease"
      data-testid="menu-section"
      :data-qa-section-name="item.title"
    >
      <slot>
        <ul :aria-label="item.title" class="gl-list-style-none gl-p-0 gl-m-0">
          <nav-item
            v-for="subItem of item.items"
            :key="`${item.title}-${subItem.title}`"
            :item="subItem"
            @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
            @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
          />
        </ul>
      </slot>
    </gl-collapse>
  </component>
</template>
