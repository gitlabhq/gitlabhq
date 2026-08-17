<script>
import { GlDisclosureDropdownItem, GlLink, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import {
  DEFAULT_PIN_CONTEXT,
  CLICK_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '../constants';

export default {
  name: 'DisclosureNavItem',
  i18n: {
    pin: s__('Navigation|Pin %{title}'),
    pinItem: s__('Navigation|Pin item'),
    unpin: s__('Navigation|Unpin %{title}'),
    unpinItem: s__('Navigation|Unpin item'),
  },
  components: { GlDisclosureDropdownItem, GlLink, GlButton },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    item: {
      type: Object,
      required: true,
    },
    pinContext: {
      type: Object,
      required: false,
      default: () => ({ ...DEFAULT_PIN_CONTEXT }),
    },
  },
  emits: ['pin-add', 'pin-remove'],
  computed: {
    isPinned() {
      return this.pinContext.pinnedItemIds.ids.includes(this.item.id);
    },
    supportsPins() {
      return this.pinContext.panelSupportsPins;
    },
    // `text` satisfies the item validator; we render the link ourselves.
    // wrapperClass must be on the <li> so the pin reveals on focus-within.
    structure() {
      return {
        text: this.item.title,
        wrapperClass:
          'show-on-focus-or-hover--context transition-opacity-on-hover--context gl-relative',
      };
    },
    linkAttrs() {
      const { panelType } = this.pinContext;
      const extra =
        !this.item.id || !panelType
          ? { 'data-track-extra': JSON.stringify({ title: this.item.title }) }
          : {};
      return {
        'aria-current': this.item.is_active ? 'page' : null,
        'data-method': this.item.data_method,
        'data-qa-submenu-item': this.item.title,
        'data-track-action': CLICK_MENU_ITEM_ACTION,
        'data-track-label': this.item.id ?? TRACKING_UNKNOWN_ID,
        'data-track-property': panelType ? `nav_panel_${panelType}` : TRACKING_UNKNOWN_PANEL,
        ...extra,
      };
    },
    pinLabel() {
      const template = this.isPinned ? this.$options.i18n.unpin : this.$options.i18n.pin;
      return sprintf(template, { title: this.item.title });
    },
    pinTooltip() {
      return this.isPinned ? this.$options.i18n.unpinItem : this.$options.i18n.pinItem;
    },
    pinButtonIcon() {
      return this.isPinned ? 'thumbtack-solid' : 'thumbtack';
    },
  },
  mounted() {
    // With a custom default slot, GlDisclosureDropdownItem does not activate
    // the link on Enter/Space (it only emits an unused `action` event, then the
    // dropdown closes). Handle those keys on the item's <li> and click the link
    // ourselves so the item navigates. The pin button stops its own keydowns,
    // so they never reach here.
    this.$refs.item.$el.addEventListener('keydown', this.onKeydown);
  },
  beforeDestroy() {
    this.$refs.item.$el.removeEventListener('keydown', this.onKeydown);
  },
  methods: {
    onKeydown(event) {
      if (event.key !== 'Enter' && event.key !== ' ') return;
      event.preventDefault();
      event.stopPropagation();
      this.$refs.link.$el.click();
    },
    togglePin() {
      const event = this.isPinned ? 'pin-remove' : 'pin-add';
      this.$emit(event, this.item.id, this.item.title);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item ref="item" :item="structure">
    <template #default>
      <gl-link
        ref="link"
        class="gl-new-dropdown-item-content"
        :href="item.link"
        variant="unstyled"
        :tabindex="-1"
        v-bind="linkAttrs"
      >
        <span class="gl-new-dropdown-item-text-wrapper">{{ item.title }}</span>
      </gl-link>
      <gl-button
        v-if="supportsPins"
        v-gl-tooltip.noninteractive.right.viewport="pinTooltip"
        :aria-label="pinLabel"
        category="tertiary"
        size="small"
        class="show-on-focus-or-hover--target transition-opacity-on-hover--target always-animate gl-absolute gl-right-3 gl-top-1/2 -gl-translate-y-1/2"
        :data-testid="isPinned ? 'nav-item-unpin' : 'nav-item-pin'"
        :icon="pinButtonIcon"
        @click.stop.prevent="togglePin"
        @keydown.enter.stop.prevent="togglePin"
        @keydown.space.stop.prevent="togglePin"
      />
    </template>
  </gl-disclosure-dropdown-item>
</template>
