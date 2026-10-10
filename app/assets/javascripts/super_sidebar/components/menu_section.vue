<script>
import { kebabCase } from 'lodash-es';
import {
  GlCollapse,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlIcon,
  GlNavItem,
  GlAnimatedChevronRightDownIcon,
  GlOutsideDirective as Outside,
  GlTooltipDirective,
} from '@gitlab/ui';
import { HIDDEN_NAV_ITEM_CLASS, DEFAULT_PIN_CONTEXT } from '../constants';
import NavItem from './nav_item.vue';
import FlyoutMenu from './flyout_menu.vue';
import DisclosureNavItem from './disclosure_nav_item.vue';

export default {
  name: 'MenuSection',
  components: {
    GlCollapse,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlIcon,
    GlNavItem,
    GlAnimatedChevronRightDownIcon,
    NavItem,
    FlyoutMenu,
    DisclosureNavItem,
  },
  directives: { Outside, GlTooltip: GlTooltipDirective },
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
    disclosure: {
      type: Boolean,
      required: false,
      default: false,
    },
    // Forces the disclosure toggle to render as an icon-only button (with a
    // tooltip) even in the expanded sidebar, for use where header space is
    // tight. Only affects the disclosure toggle.
    iconOnlyToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    pinContext: {
      type: Object,
      required: false,
      default: () => ({ ...DEFAULT_PIN_CONTEXT }),
    },
    headerless: {
      type: Boolean,
      required: false,
      default: false,
    },
    boldTitle: {
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
  emits: ['collapse-toggle', 'nav-link-click', 'pin-add', 'pin-remove'],
  data() {
    return {
      isExpanded: Boolean(this.headerless || this.expanded || this.item.is_active),
      isMouseOverSection: false,
      isMouseOverFlyout: false,
      keepFlyoutClosed: false,
    };
  },
  computed: {
    navItems() {
      return this.item.items.filter((item) => {
        if (item.link_classes) {
          return !item.link_classes.includes(HIDDEN_NAV_ITEM_CLASS);
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
    toggleIsIconOnly() {
      return this.iconOnlyToggle || this.isIconOnly;
    },
    // Only icon-only toggles need a tooltip (the label is hidden). Anchor it
    // above the button in the header (forced icon-only via iconOnlyToggle) and
    // to the right in the collapsed sidebar (injected isIconOnly).
    toggleTooltip() {
      if (!this.toggleIsIconOnly) return { title: '' };

      if (this.iconOnlyToggle) {
        // Keep the header tooltip from being clipped at the top of the viewport.
        return { title: this.item.title, placement: 'top', boundary: 'viewport' };
      }

      return { title: this.item.title, placement: 'right' };
    },
    // A headerless section has no toggle to reveal its items, so keep the
    // collapse open regardless of the (stale) expanded state carried over from
    // the expanded sidebar.
    collapseVisible() {
      return this.headerless || this.isExpanded;
    },
    showFlyout() {
      return (
        !this.headerless &&
        this.hasFlyout &&
        this.isMouseOver &&
        !this.showExpanded &&
        !this.keepFlyoutClosed &&
        this.navItems.length > 0
      );
    },
  },
  watch: {
    isExpanded(newIsExpanded) {
      this.$emit('collapse-toggle', newIsExpanded);
      this.keepFlyoutClosed = !newIsExpanded && !this.isIconOnly;
      if (!newIsExpanded) {
        this.isMouseOverFlyout = false;
      }
    },
    isIconOnly(newIsIconOnly) {
      // Reset keepFlyoutClosed when toggling between expanded/collapsed sidebar
      if (newIsIconOnly) {
        this.keepFlyoutClosed = false;
      }
    },
    headerless(newHeaderless) {
      // A headerless section is force-expanded, so isExpanded may have been
      // initialized to true regardless of the real (cookie-backed) state. When
      // the header reappears, re-sync to the actual expanded prop so the group
      // honors its own collapse state instead of staying stuck open.
      if (!newHeaderless) {
        this.isExpanded = Boolean(this.expanded || this.item.is_active);
      }
    },
  },
  methods: {
    onCollapseInput(visible) {
      // Ignore the forced-open state of a headerless section so its stale
      // expanded state (from the expanded sidebar) is preserved.
      if (this.headerless) return;
      this.isExpanded = visible;
    },
    handleClick() {
      if (this.isIconOnly) {
        this.isMouseOverSection = !this.isMouseOverSection; // Allows touch devices to open the flyout menus by touch
        return;
      }
      this.isExpanded = !this.isExpanded;
    },
    handleClickOutside(targetId) {
      this.isMouseOverSection = false; // Allows touch devices to close the flyout menus by touch
      if (targetId) {
        document.getElementById(targetId)?.focus();
      }
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
    <gl-disclosure-dropdown v-if="disclosure" class="super-sidebar-settings-dropdown" block>
      <template #toggle="{ accessibilityAttributes }">
        <gl-nav-item
          v-gl-tooltip="toggleTooltip"
          :icon="item.icon"
          :is-icon-only="toggleIsIconOnly"
          :aria-label="item.title"
          :selected="item.is_active"
          data-testid="menu-section-button"
          :data-qa-section-name="item.title"
          v-bind="accessibilityAttributes"
        >
          {{ item.title }}
        </gl-nav-item>
      </template>

      <gl-disclosure-dropdown-group>
        <disclosure-nav-item
          v-for="navItem in navItems"
          :key="navItem.id"
          :item="navItem"
          :pin-context="pinContext"
          @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
          @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
        />
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <gl-nav-item
      v-if="!disclosure && !headerless"
      :id="`menu-section-button-${itemId}`"
      v-outside="handleClickOutside"
      class="gl-relative gl-mb-1"
      :class="computedLinkClasses"
      data-testid="menu-section-button"
      :data-qa-section-name="item.title"
      :aria-label="item.title"
      :icon="item.icon"
      :is-icon-only="isIconOnly"
      :expanded="isExpanded"
      :selected="isActive"
      is-parent
      v-bind="buttonProps"
      @click="handleClick"
      @escape="handleClickOutside"
      @pointerover="handlePointerover"
      @pointerleave="handlePointerleave"
    >
      <span
        class="gl-truncate-end menu-section-button-label"
        :class="{ 'gl-font-bold': boldTitle }"
      >
        {{ item.title }}
      </span>
    </gl-nav-item>

    <flyout-menu
      v-if="!disclosure && showFlyout"
      :target-id="`menu-section-button-${itemId}`"
      :title="item.title"
      :items="navItems"
      :async-count="asyncCount"
      @mouseover="isMouseOverFlyout = true"
      @mouseleave="isMouseOverFlyout = false"
      @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
      @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
      @nav-link-click="$emit('nav-link-click')"
      @nav-item-keydown-esc="handleClickOutside"
      @nav-pin-keydown-esc="handleClickOutside"
    />

    <gl-collapse
      v-if="!disclosure"
      :id="itemId"
      :visible="collapseVisible"
      :class="{ 'gl-hidden': isIconOnly && !headerless }"
      class="gl-m-0 gl-list-none gl-p-0 gl-transition-[height] gl-duration-medium gl-ease-ease"
      data-testid="menu-section"
      :data-qa-section-name="item.title"
      @input="onCollapseInput"
    >
      <slot>
        <ul :aria-label="item.title" class="gl-m-0 gl-list-none gl-p-0">
          <nav-item
            v-for="subItem of navItems"
            :key="`${item.title}-${subItem.title}`"
            :item="subItem"
            :async-count="asyncCount"
            hide-icon
            @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
            @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
          />
        </ul>
      </slot>
    </gl-collapse>
  </component>
</template>
