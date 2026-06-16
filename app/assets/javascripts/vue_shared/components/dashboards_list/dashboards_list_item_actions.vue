<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'DashboardsListItemActions',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inheritAttrs: false,
  props: {
    actionLabel: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.hover
    icon="ellipsis_v"
    category="tertiary"
    :title="actionLabel"
    no-caret
    left
    :toggle-text="__('More actions')"
    text-sr-only
  >
    <gl-disclosure-dropdown-item>
      <template #list-item>
        {{ __('Share') }}
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
