<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import dashboardsListItemActionsMixin from './dashboards_list_item_actions_mixin';

export default {
  name: 'DashboardsListItemActions',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [dashboardsListItemActionsMixin],
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
    :title="__('More actions')"
    no-caret
    placement="bottom-end"
    :toggle-text="actionLabel"
    text-sr-only
  >
    <gl-disclosure-dropdown-item
      :item="openDashboardItem"
      icon="dashboard"
      data-testid="dashboard-open-action"
    />
    <gl-disclosure-dropdown-item
      :item="$options.copyLinkItem"
      icon="link"
      data-testid="dashboard-copy-link-action"
      :data-clipboard-text="absoluteDashboardUrl"
      @action="handleCopyLinkAction"
    />
  </gl-disclosure-dropdown>
</template>
