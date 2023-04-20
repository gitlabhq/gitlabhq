<script>
import { kebabCase } from 'lodash';
import { GlButton, GlCollapse, GlIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  CLICK_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '~/super_sidebar/constants';

export default {
  i18n: {
    pinItem: s__('Navigation|Pin item'),
    unpinItem: s__('Navigation|Unpin item'),
  },
  name: 'NavItem',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlBadge,
  },
  inject: {
    pinnedItemIds: { default: { ids: [] } },
    panelSupportsPins: { default: false },
    panelType: { default: '' },
  },
  props: {
    draggable: {
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
  },
  data() {
    return {
      expanded: this.item.is_active,
    };
  },
  computed: {
    elem() {
      return this.isSection ? 'button' : 'a';
    },
    collapseIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    isSection() {
      return Boolean(this.item?.items?.length);
    },
    itemId() {
      return kebabCase(this.item.title);
    },
    pillData() {
      return this.item.pill_count;
    },
    hasPill() {
      return (
        Number.isFinite(this.pillData) ||
        (typeof this.pillData === 'string' && this.pillData !== '')
      );
    },
    isActive() {
      if (this.isSection) {
        return !this.expanded && this.item.is_active;
      }
      return this.item.is_active;
    },
    isPinnable() {
      return this.panelSupportsPins && !this.isSection && !this.isStatic;
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
        'data-track-action': CLICK_MENU_ITEM_ACTION,
        'data-track-label': this.item.id ?? TRACKING_UNKNOWN_ID,
        'data-track-property': this.panelType
          ? `nav_panel_${this.panelType}`
          : TRACKING_UNKNOWN_PANEL,
        ...extraData,
      };
    },
    linkProps() {
      if (this.isSection) {
        return {
          'aria-controls': this.itemId,
          'aria-expanded': String(this.expanded),
          'data-qa-menu-item': this.item.title,
        };
      }
      return {
        ...this.$attrs,
        ...this.trackingProps,
        href: this.item.link,
        'aria-current': this.isActive ? 'page' : null,
        'data-qa-submenu-item': this.item.title,
      };
    },
    computedLinkClasses() {
      return {
        // Reset user agent styles on <button>
        'gl-appearance-none gl-border-0 gl-bg-transparent gl-text-left': this.isSection,
        'gl-w-full gl-focus--focus': this.isSection,
        'nav-item-link': !this.isSection,
        'gl-bg-t-gray-a-08': this.isActive,
        'gl-py-2': this.isPinnable,
        'gl-py-3': !this.isPinnable,
        [this.item.link_classes]: this.item.link_classes,
        ...this.linkClasses,
      };
    },
  },
  methods: {
    click(event) {
      if (this.isSection) {
        event.preventDefault();
        this.expanded = !this.expanded;
      }
    },
  },
};
</script>

<template>
  <li>
    <component
      :is="elem"
      v-bind="linkProps"
      class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-mb-1 gl-px-0 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-text-decoration-none!"
      :class="computedLinkClasses"
      data-qa-selector="nav_item_link"
      data-testid="nav-item-link"
      @click="click"
    >
      <div
        :class="[isActive ? 'gl-bg-blue-500' : 'gl-bg-transparent']"
        class="gl-absolute gl-left-2 gl-top-2 gl-bottom-2 gl-transition-slow"
        aria-hidden="true"
        style="width: 3px; border-radius: 3px; margin-right: 1px"
      ></div>
      <div class="gl-flex-shrink-0 gl-w-6 gl-mx-3">
        <slot name="icon">
          <gl-icon v-if="item.icon" :name="item.icon" class="gl-ml-2 item-icon" />
          <gl-icon
            v-else-if="draggable"
            name="grip"
            class="gl-text-gray-400 gl-ml-2 draggable-icon"
          />
        </slot>
      </div>
      <div class="gl-pr-3 gl-text-gray-900 gl-truncate-end">
        {{ item.title }}
        <div v-if="item.subtitle" class="gl-font-sm gl-text-gray-500 gl-truncate-end">
          {{ item.subtitle }}
        </div>
      </div>
      <slot name="actions"></slot>
      <span v-if="isSection || hasPill || isPinnable" class="gl-flex-grow-1 gl-text-right gl-mr-3">
        <gl-badge v-if="hasPill" size="sm" variant="info">
          {{ pillData }}
        </gl-badge>
        <gl-icon v-else-if="isSection" :name="collapseIcon" />
        <gl-button
          v-else-if="isPinnable && !isPinned"
          size="small"
          category="tertiary"
          icon="thumbtack"
          :aria-label="$options.i18n.pinItem"
          @click.prevent="$emit('pin-add', item.id)"
        />
        <gl-button
          v-else-if="isPinnable && isPinned"
          size="small"
          category="tertiary"
          :aria-label="$options.i18n.unpinItem"
          icon="thumbtack-solid"
          @click.prevent="$emit('pin-remove', item.id)"
        />
      </span>
    </component>
    <gl-collapse
      v-if="isSection"
      :id="itemId"
      v-model="expanded"
      data-qa-selector="menu_section"
      :data-qa-section="item.title"
      :aria-label="item.title"
      class="gl-list-style-none gl-p-0"
      tag="ul"
    >
      <nav-item
        v-for="subItem of item.items"
        :key="`${item.title}-${subItem.title}`"
        :item="subItem"
        @pin-add="(itemId) => $emit('pin-add', itemId)"
        @pin-remove="(itemId) => $emit('pin-remove', itemId)"
      />
    </gl-collapse>
  </li>
</template>
