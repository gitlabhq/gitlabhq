<script>
import { GlButton, GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import {
  SIDEBAR_NAV_MODE_PINNED_ONLY,
  SIDEBAR_NAV_MODE_ALL_CATEGORIES,
  SIDEBAR_NAV_MODE_GROUPED_PINS,
} from '../constants';
import { EVENT_SELECT_SIDEBAR_NAVIGATION_MODE_IN_SIDEBAR_PREFERENCES } from '../tracking_constants';

// Ordered least to most expansive; "category" is the sole noun (the concept the
// rest of this feature uses), so "group" stays out of the visible copy even
// though the mode is internally SIDEBAR_NAV_MODE_GROUPED_PINS.
const ITEMS = [
  {
    value: SIDEBAR_NAV_MODE_PINNED_ONLY,
    text: s__('Navigation|Flat'),
    description: s__('Navigation|Pinned only'),
  },
  {
    value: SIDEBAR_NAV_MODE_GROUPED_PINS,
    text: s__('Navigation|Organized'),
    description: s__('Navigation|Pinned in categories'),
  },
  {
    value: SIDEBAR_NAV_MODE_ALL_CATEGORIES,
    text: s__('Navigation|Everything'),
    description: s__('Navigation|All categories'),
  },
];

export default {
  name: 'SidebarPreferences',
  components: {
    GlButton,
    GlCollapsibleListbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  inject: {
    panelType: { default: '' },
  },
  props: {
    mode: {
      type: String,
      required: false,
      default: SIDEBAR_NAV_MODE_PINNED_ONLY,
    },
  },
  emits: ['select'],
  i18n: {
    customizeSidebar: s__('Navigation|Customize sidebar'),
  },
  items: ITEMS,
  methods: {
    onSelect(mode) {
      if (mode === this.mode) return;

      // A single event carries the chosen mode as `property` so each option can
      // be counted directly, rather than inferred from on/off toggle pairs.
      this.trackEvent(EVENT_SELECT_SIDEBAR_NAVIGATION_MODE_IN_SIDEBAR_PREFERENCES, {
        label: this.panelType,
        property: mode,
      });
      this.$emit('select', mode);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    placement="right"
    class="gl-shrink-0"
    data-testid="sidebar-preferences"
    :items="$options.items"
    :selected="mode"
    :header-text="$options.i18n.customizeSidebar"
    @select="onSelect"
  >
    <template #toggle="{ accessibilityAttributes }">
      <gl-button
        v-gl-tooltip.hover
        :title="$options.i18n.customizeSidebar"
        :aria-label="$options.i18n.customizeSidebar"
        icon="ellipsis_h"
        category="tertiary"
        size="small"
        class="-gl-mr-2"
        v-bind="accessibilityAttributes"
      />
    </template>
    <template #list-item="{ item }">
      <span class="gl-block">{{ item.text }}</span>
      <span class="gl-block gl-text-sm gl-text-subtle">{{ item.description }}</span>
    </template>
  </gl-collapsible-listbox>
</template>
