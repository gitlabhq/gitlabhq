<script>
import { GlAvatar, GlBadge, GlButton, GlIcon, GlNavItem, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import {
  CLICK_MENU_ITEM_ACTION,
  CLICK_PINNED_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '~/super_sidebar/constants';
import { ariaCurrent } from '../utils';

export default {
  i18n: {
    pin: s__('Navigation|Pin %{title}'),
    pinItem: s__('Navigation|Pin item'),
    unpin: s__('Navigation|Unpin %{title}'),
    unpinItem: s__('Navigation|Unpin item'),
  },
  name: 'NavItem',
  components: {
    GlAvatar,
    GlBadge,
    GlButton,
    GlIcon,
    GlNavItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    pinnedItemIds: { default: { ids: [] } },
    panelSupportsPins: { default: false },
    panelType: { default: '' },
    isIconOnly: { default: false },
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
    asyncCount: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['nav-item-keydown-esc', 'nav-link-click', 'nav-pin-keydown-esc', 'pin-add', 'pin-remove'],
  data() {
    return {
      isMouseIn: false,
      canClickPinButton: false,
    };
  },
  computed: {
    pillData() {
      if (this.item.pill_count_field) {
        const countField = this.item.pill_count_field;
        const hasAsyncCount = Object.prototype.hasOwnProperty.call(this.asyncCount, countField);

        return hasAsyncCount ? this.asyncCount[countField] : '-';
      }
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
    /**
     * Some QA specs rely on a stable "Project overview"/"Group overview" nav
     * item data-qa-submenu-item attribute value.
     *
     * This computed ensures that those particular nav items use the `id` of
     * the item rather than its title for that QA attribute.
     *
     * In future, probably all nav items should do this, for consistency.
     * See https://gitlab.com/gitlab-org/gitlab/-/issues/422925.
     */
    qaSubMenuItem() {
      const { id } = this.item;
      if (id === 'project_overview' || id === 'group_overview') return id.replace(/_/g, '-');
      return this.item.title;
    },
    linkProps() {
      return {
        ...this.$attrs,
        ...this.trackingProps,
        'aria-current': ariaCurrent(this.isActive),
        selected: this.isActive,
        href: this.item.link,
        to: this.item.to,
        'data-qa-submenu-item': this.qaSubMenuItem,
        'data-method': this.item.data_method ?? null,
      };
    },
    computedLinkClasses() {
      return {
        'gl-px-2 gl-mx-2 gl-leading-normal': this.isSubitem,
        'gl-px-2': !this.isSubitem,
        '!gl-pl-5 gl-rounded-default': this.isFlyout,
        [this.item.link_classes]: this.item.link_classes,
        ...this.linkClasses,
      };
    },
    hasAvatar() {
      return Boolean(this.item.entity_id);
    },
    hasEndSpace() {
      return this.hasPill || this.isPinnable || this.isFlyout;
    },
    avatarShape() {
      return this.item.avatar_shape || 'rect';
    },
    pinAriaLabel() {
      return sprintf(this.$options.i18n.pin, {
        title: this.item.title,
      });
    },
    unpinAriaLabel() {
      return sprintf(this.$options.i18n.unpin, {
        title: this.item.title,
      });
    },
    isActive() {
      return this.item.is_active;
    },
    hasBadge() {
      return Boolean(this.item.badge);
    },
  },
  mounted() {
    if (this.isActive && !this.isFlyout) {
      this.$el.scrollIntoView({
        behavior: 'instant',
        block: 'center',
        inline: 'nearest',
      });
    }
  },
  methods: {
    pinAdd() {
      // Reset mouse state before emitting to prevent Safari bug where mouseleave
      // doesn't fire when the element is removed from DOM
      this.isMouseIn = false;
      this.$emit('pin-add', this.item.id, this.item.title);
    },
    pinRemove() {
      // Reset mouse state before emitting to prevent Safari bug where mouseleave
      // doesn't fire when the element is removed from DOM
      this.isMouseIn = false;
      this.$emit('pin-remove', this.item.id, this.item.title);
    },
    togglePointerEvents() {
      this.canClickPinButton = this.isMouseIn;
    },
  },
};
</script>

<template>
  <li
    v-gl-tooltip.right.viewport="isIconOnly && !isFlyout ? item.title : ''"
    class="show-on-focus-or-hover--context hide-on-focus-or-hover--context transition-opacity-on-hover--context gl-relative"
    data-testid="nav-item"
    @mouseenter="isMouseIn = true"
    @mouseleave="isMouseIn = false"
  >
    <gl-nav-item
      v-bind="linkProps"
      class="super-sidebar-nav-item show-on-focus-or-hover--control hide-on-focus-or-hover--control gl-mb-1"
      :class="computedLinkClasses"
      data-testid="nav-item-link"
      :aria-label="item.title"
      :is-icon-only="!isFlyout ? isIconOnly : false"
      @click="$emit('nav-link-click')"
      @escape="$emit('nav-item-keydown-esc')"
    >
      <template v-if="!isFlyout" #icon>
        <span
          class="gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center"
          :class="{
            'gl-self-start': hasAvatar,
            'gl-rounded-base gl-bg-default': hasAvatar && avatarShape === 'rect',
            '-gl-mr-2': hasAvatar && isIconOnly,
          }"
        >
          <slot name="icon">
            <gl-icon v-if="item.icon" :name="item.icon" />
            <gl-icon
              v-else-if="isInPinnedSection"
              name="grip"
              class="js-draggable-icon show-on-focus-or-hover--target super-sidebar-mix-blend-mode gl-cursor-grab"
              variant="subtle"
            />
            <gl-avatar
              v-else-if="hasAvatar"
              :size="24"
              :shape="avatarShape"
              :entity-name="item.title"
              :entity-id="item.entity_id"
              :src="item.avatar"
            />
          </slot>
        </span>
      </template>
      <span
        v-show="!isIconOnly"
        class="gl-grow gl-break-anywhere"
        :class="{ 'nav-item-link-label': !isFlyout }"
        data-testid="nav-item-link-label"
      >
        {{ item.title }}
        <gl-badge
          v-if="hasBadge"
          variant="info"
          size="sm"
          data-testid="nav-item-feature-announcement-badge"
        >
          {{ item.badge.label }}
        </gl-badge>
        <span v-if="item.subtitle" class="gl-truncate-end gl-text-sm gl-text-subtle">
          {{ item.subtitle }}
        </span>
      </span>
      <slot name="actions"></slot>
      <template v-if="hasEndSpace && !isIconOnly" #end>
        <span
          v-if="hasPill"
          class="nav-item-link-badge gl-mr-3 gl-text-sm"
          :class="{
            'hide-on-focus-or-hover--target transition-opacity-on-hover--target': isPinnable,
          }"
          data-testid="pill-badge"
        >
          {{ pillData }}
        </span>
      </template>
    </gl-nav-item>
    <gl-button
      v-if="isPinnable"
      v-gl-tooltip.noninteractive.right.viewport="
        isPinned ? $options.i18n.unpinItem : $options.i18n.pinItem
      "
      :aria-label="isPinned ? unpinAriaLabel : pinAriaLabel"
      category="tertiary"
      class="show-on-focus-or-hover--target transition-opacity-on-hover--target always-animate gl-absolute gl-right-3 gl-top-1/2 -gl-translate-y-1/2"
      :class="{ 'gl-pointer-events-none': !canClickPinButton }"
      :data-testid="isPinned ? 'nav-item-unpin' : 'nav-item-pin'"
      :icon="isPinned ? 'thumbtack-solid' : 'thumbtack'"
      size="small"
      @click="isPinned ? pinRemove() : pinAdd()"
      @keydown.enter.stop.prevent="isPinned ? pinRemove() : pinAdd()"
      @keydown.space.stop.prevent="isPinned ? pinRemove() : pinAdd()"
      @keydown.escape="$emit('nav-pin-keydown-esc')"
      @transitionend="togglePointerEvents"
    />
  </li>
</template>
