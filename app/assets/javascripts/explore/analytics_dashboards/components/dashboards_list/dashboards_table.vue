<script>
import { GlTableLite } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DashboardsListItemActions from 'ee_else_ce/explore/analytics_dashboards/components/dashboards_list/dashboards_list_item_actions.vue';
import DashboardsListAuthor from './dashboards_list_author.vue';
import DashboardsListNameCell from './dashboards_list_name_cell.vue';

export default {
  name: 'DashboardsTable',
  components: {
    GlTableLite,
    DashboardsListAuthor,
    DashboardsListItemActions,
    DashboardsListNameCell,
    TimeAgoTooltip,
  },
  props: {
    dashboards: {
      type: Array,
      required: true,
    },
  },
  methods: {
    actionsLabel({ name }) {
      return sprintf(s__('AnalyticsDashboards|More actions for %{name}'), { name }, false);
    },
    // Formats the time the same way as the default-configured TimeAgoTooltip that
    // renders the visible text.
    lastEditedLabel({ updatedAt }) {
      return sprintf(s__('AnalyticsDashboards|Last edited %{timeAgo}'), {
        timeAgo: getTimeago().format(updatedAt, timeagoLanguageCode),
      });
    },
  },
  fields: [
    { key: 'name', label: __('Title') },
    // Stacked rows drop an empty cell rather than print a label with nothing beside it: a
    // custom dashboard whose creator was deleted has no author, and a system dashboard has no
    // edit time. The query matches `stacked="md"`.
    {
      key: 'author',
      label: s__('AnalyticsDashboards|Created by'),
      tdClass: (value, key, item) =>
        item.system || item.createdBy ? '' : '@max-md/panel:!gl-hidden',
    },
    {
      key: 'updatedAt',
      label: s__('AnalyticsDashboards|Last edited'),
      tdClass: (updatedAt) => (updatedAt ? '' : '@max-md/panel:!gl-hidden'),
    },
    // No label, so the stacked mobile layout doesn't print a visible "Actions"
    // beside the menu, which already has its own accessible name.
    { key: 'actions', label: '', thClass: 'gl-w-0', tdClass: 'gl-text-right' },
  ],
};
</script>
<template>
  <gl-table-lite
    :items="dashboards"
    :fields="$options.fields"
    primary-key="id"
    stacked="md"
    :aria-label="s__('AnalyticsDashboards|Dashboards')"
    data-testid="dashboards-list"
  >
    <template #head(actions)>
      <span class="gl-sr-only">{{ __('Actions') }}</span>
    </template>
    <template #cell(name)="{ item }">
      <dashboards-list-name-cell
        :name="item.name"
        :description="item.description"
        :dashboard-url="item.dashboardUrl"
      />
    </template>
    <template #cell(author)="{ item }">
      <dashboards-list-author :dashboard="item" />
    </template>
    <template #cell(updatedAt)="{ item }">
      <time-ago-tooltip
        v-if="item.updatedAt"
        :aria-label="lastEditedLabel(item)"
        :time="item.updatedAt"
        class="gl-whitespace-nowrap"
        data-testid="dashboard-updated-at"
      />
    </template>
    <template #cell(actions)="{ item }">
      <dashboards-list-item-actions
        :id="item.id"
        :name="item.name"
        :action-label="actionsLabel(item)"
        :dashboard-url="item.dashboardUrl"
        :system="item.system"
      />
    </template>
  </gl-table-lite>
</template>
