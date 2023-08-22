<script>
import { GlButton, GlIcon, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  CLICK_MENU_ITEM_ACTION,
  CLICK_PINNED_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '~/super_sidebar/constants';
import NavItemLink from './nav_item_link.vue';
import NavItemRouterLink from './nav_item_router_link.vue';

export default {
  i18n: {
    pinItem: s__('Navigation|Pin item'),
    unpinItem: s__('Navigation|Unpin item'),
  },
  name: 'NavItem',
  components: {
    GlButton,
    GlIcon,
    GlBadge,
    NavItemLink,
    NavItemRouterLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    pinnedItemIds: { default: { ids: [] } },
    panelSupportsPins: { default: false },
    panelType: { default: '' },
  },
  props: {
    isInPinnedSection: {
      type: Boolean,
      required: false,
      default: false,
    },
    isStatic: {
      type: Boolean,
      required: false,
      default: false,
    },
    item: {
      type: Object,
      required: true,
    },
    linkClasses: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isSubitem: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFlyout: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    pillData() {
      return this.item.pill_count;
    },
    hasPill() {
      return (
        Number.isFinite(this.pillData) ||
        (typeof this.pillData === 'string' && this.pillData !== '')
      );
    },
    isPinnable() {
      return this.panelSupportsPins && !this.isStatic;
    },
    isPinned() {
      return this.pinnedItemIds.ids.includes(this.item.id);
    },
    trackingProps() {
      // Set extra event data to debug missing IDs / Panel Types
      const extraData =
        !this.item.id || !this.panelType
          ? { 'data-track-extra': JSON.stringify({ title: this.item.title }) }
          : {};

      return {
        'data-track-action': this.isInPinnedSection
          ? CLICK_PINNED_MENU_ITEM_ACTION
          : CLICK_MENU_ITEM_ACTION,
        'data-track-label': this.item.id ?? TRACKING_UNKNOWN_ID,
        'data-track-property': this.panelType
          ? `nav_panel_${this.panelType}`
          : TRACKING_UNKNOWN_PANEL,
        ...extraData,
      };
    },
    linkProps() {
      return {
        ...this.$attrs,
        ...this.trackingProps,
        item: this.item,
        'data-qa-submenu-item': this.item.title,
        'data-method': this.item.data_method ?? null,
      };
    },
    computedLinkClasses() {
      return {
        'gl-px-2 gl-mx-2 gl-line-height-normal': this.isSubitem,
        'gl-px-3': !this.isSubitem,
        'gl-pl-5! gl-rounded-small': this.isFlyout,
        'gl-rounded-base': !this.isFlyout,
        [this.item.link_classes]: this.item.link_classes,
        ...this.linkClasses,
      };
    },
    navItemLinkComponent() {
      return this.item.to ? NavItemRouterLink : NavItemLink;
    },
  },
};
</script>

<template>
  <li>
    <component
      :is="navItemLinkComponent"
      #default="{ isActive }"
      v-bind="linkProps"
      class="nav-item-link gl-relative gl-display-flex gl-align-items-center gl-min-h-7 gl-gap-3 gl-mb-1 gl-py-2 gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-text-decoration-none! gl-focus--focus show-on-focus-or-hover--context"
      :class="computedLinkClasses"
      data-qa-selector="nav_item_link"
      data-testid="nav-item-link"
    >
      <div
        :class="[isActive ? 'gl-opacity-10' : 'gl-opacity-0']"
        class="active-indicator gl-bg-blue-500 gl-absolute gl-left-2 gl-top-2 gl-bottom-2 gl-transition-slow"
        aria-hidden="true"
        style="width: 3px; border-radius: 3px; margin-right: 1px"
        data-testid="active-indicator"
      ></div>
      <div v-if="!isFlyout" class="gl-flex-shrink-0 gl-w-6 gl-display-flex">
        <slot name="icon">
          <gl-icon v-if="item.icon" :name="item.icon" class="gl-m-auto item-icon" />
          <gl-icon
            v-else-if="isInPinnedSection"
            name="grip"
            class="gl-m-auto gl-text-gray-400 js-draggable-icon gl-cursor-grab show-on-focus-or-hover--target"
          />
        </slot>
      </div>
      <div class="gl-flex-grow-1 gl-text-gray-900 gl-truncate-end">
        {{ item.title }}
        <div v-if="item.subtitle" class="gl-font-sm gl-text-gray-500 gl-truncate-end">
          {{ item.subtitle }}
        </div>
      </div>
      <slot name="actions"></slot>
      <span v-if="hasPill || isPinnable" class="gl-text-right gl-relative gl-min-w-8">
        <gl-badge
          v-if="hasPill"
          size="sm"
          variant="neutral"
          class="gl-bg-t-gray-a-08!"
          :class="{ 'nav-item-badge gl-absolute gl-right-0 gl-top-2': isPinnable }"
        >
          {{ pillData }}
        </gl-badge>
        <gl-button
          v-if="isPinnable && !isPinned"
          v-gl-tooltip.noninteractive.ds500.right.viewport="$options.i18n.pinItem"
          size="small"
          category="tertiary"
          icon="thumbtack"
          class="show-on-focus-or-hover--target"
          :aria-label="$options.i18n.pinItem"
          @click.prevent="$emit('pin-add', item.id)"
        />
        <gl-button
          v-else-if="isPinnable && isPinned"
          v-gl-tooltip.noninteractive.ds500.right.viewport="$options.i18n.unpinItem"
          size="small"
          category="tertiary"
          :aria-label="$options.i18n.unpinItem"
          icon="thumbtack-solid"
          class="show-on-focus-or-hover--target"
          @click.prevent="$emit('pin-remove', item.id)"
        />
      </span>
    </component>
  </li>
</template>
