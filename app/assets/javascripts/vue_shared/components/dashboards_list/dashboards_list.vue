<script>
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { GlTable, GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime/timeago_utility';
import DashboardsListItemActions from 'ee_else_ce/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';
import DashboardsListNameCell from './dashboards_list_name_cell.vue';

export default {
  name: 'DashboardsList',
  components: {
    GlTable,
    GlAvatarLabeled,
    GlAvatarLink,
    DashboardsListNameCell,
    DashboardsListItemActions,
  },
  props: {
    dashboards: {
      type: Array,
      required: true,
    },
  },
  methods: {
    formatUpdatedAt(updatedAt) {
      return getTimeago().format(updatedAt);
    },
  },
  avatarSize: 24,
  fields: [
    {
      key: 'name',
      label: __('Title'),
    },
    {
      key: 'createdBy',
      label: __('Created by'),
      tdClass: '!gl-align-bottom',
    },
    {
      key: 'updatedAt',
      label: __('Last edited'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'actions',
      tdClass: '!gl-text-right',
      label: __('Actions'),
    },
  ],
  createdByGitLab: {
    avatarUrl: GITLAB_LOGO_SVG_URL,
    label: __('GitLab'),
  },
};
</script>
<template>
  <div>
    <gl-table stacked="sm" :items="dashboards" :fields="$options.fields">
      <template #head(actions)="column"
        ><span class="gl-sr-only">{{ column.label }}</span></template
      >
      <template #cell(name)="{ item: { name, isStarred, description, dashboardUrl } }">
        <dashboards-list-name-cell
          :name="name"
          :description="description"
          :is-starred="isStarred"
          :dashboard-url="dashboardUrl"
        />
      </template>
      <template #cell(createdBy)="{ item: { createdBy, system } }">
        <gl-avatar-labeled
          v-if="system"
          :src="$options.createdByGitLab.avatarUrl"
          :size="$options.avatarSize"
          :label="$options.createdByGitLab.label"
          shape="circle"
          fallback-on-error
        />
        <gl-avatar-link v-else target="_blank" :href="createdBy.webPath">
          <gl-avatar-labeled
            :src="createdBy.avatarUrl"
            :size="$options.avatarSize"
            :label="createdBy.name"
            shape="circle"
            fallback-on-error
          />
        </gl-avatar-link>
      </template>
      <template #cell(updatedAt)="{ item: { system, updatedAt } }">
        <span v-if="!system" data-testid="dashboard-updated-at">{{
          formatUpdatedAt(updatedAt)
        }}</span>
      </template>
      <template #cell(actions)="{ field, item: { id, system, dashboardUrl } }">
        <dashboards-list-item-actions
          :id="id"
          :system="system"
          :dashboard-url="dashboardUrl"
          :action-label="field.label"
        />
      </template>
    </gl-table>
  </div>
</template>
