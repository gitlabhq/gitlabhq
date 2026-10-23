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
  <div>
    <!-- EE fills this slot with the delete modal -->
    <slot name="ee-delete-modal"></slot>

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

      <!-- EE fills this slot with the Delete group -->
      <slot name="ee-delete-actions"></slot>
    </gl-disclosure-dropdown>
  </div>
</template>
