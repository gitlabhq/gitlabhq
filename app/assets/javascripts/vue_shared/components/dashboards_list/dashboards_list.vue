<script>
import {
  GlTable,
  GlAvatarLabeled,
  GlAvatarLink,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import DashboardsListNameCell from './dashboards_list_name_cell.vue';

export default {
  name: 'DashboardsList',
  components: {
    GlTable,
    GlAvatarLabeled,
    GlAvatarLink,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    DashboardsListNameCell,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    dashboards: {
      type: Array,
      required: true,
    },
  },
  methods: {
    dashboardUrl(slug) {
      // NOTE: this should either be a URL or vue router redirect
      return `/${slug}`;
    },
  },
  actions: {
    items: [
      {
        text: __('Edit'),
        action: () => {},
      },
      {
        text: __('Make a copy'),
        action: () => {},
      },
      {
        text: __('Share'),
        action: () => {},
      },
    ],
  },
  additionalActions: {
    items: [
      {
        text: __('Delete'),
        action: () => {},
        variant: 'danger',
      },
    ],
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
};
</script>
<template>
  <gl-table stacked="sm" :items="dashboards" :fields="$options.fields">
    <template #head(actions)="column"
      ><span class="gl-sr-only">{{ column.label }}</span></template
    >
    <template #cell(name)="{ item: { name, isStarred, description, slug } }">
      <dashboards-list-name-cell
        :name="name"
        :description="description"
        :is-starred="isStarred"
        :dashboard-url="dashboardUrl(slug)"
      />
    </template>
    <template #cell(createdBy)="{ item: { createdBy } }">
      <gl-avatar-link target="_blank" :href="createdBy.webPath">
        <gl-avatar-labeled
          :src="createdBy.avatarUrl"
          :size="$options.avatarSize"
          :label="createdBy.name"
          shape="circle"
          fallback-on-error
        />
      </gl-avatar-link>
    </template>
    <template #cell(actions)="{ field }">
      <gl-disclosure-dropdown
        v-gl-tooltip.hover
        icon="ellipsis_v"
        category="tertiary"
        :title="field.label"
        no-caret
        left
        data-testid="dashboard-actions"
        toggle-text="More actions"
        text-sr-only
      >
        <gl-disclosure-dropdown-group :group="$options.actions" />
        <gl-disclosure-dropdown-group bordered :group="$options.additionalActions" />
      </gl-disclosure-dropdown>
    </template>
  </gl-table>
</template>
