<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['groupFullPath', 'groupIssuesPath'],
  data() {
    return {
      error: false,
      organizations: [],
    };
  },
  apollo: {
    organizations: {
      query() {
        return getGroupOrganizationsQuery;
      },
      variables() {
        return {
          groupFullPath: this.groupFullPath,
        };
      },
      update(data) {
        return this.extractOrganizations(data);
      },
      error() {
        this.error = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.organizations.loading;
    },
  },
  methods: {
    extractOrganizations(data) {
      const organizations = data?.group?.organizations?.nodes || [];
      return organizations.slice().sort((a, b) => a.name.localeCompare(b.name));
    },
    dismissError() {
      this.error = false;
    },
    getIssuesPath(path, value) {
      return `${path}?scope=all&state=opened&crm_organization_id=${value}`;
    },
  },
  fields: [
    { key: 'name', sortable: true },
    { key: 'defaultRate', sortable: true },
    { key: 'description', sortable: true },
    {
      key: 'id',
      label: __('Issues'),
      formatter: (id) => {
        return getIdFromGraphQLId(id);
      },
    },
  ],
  i18n: {
    emptyText: s__('Crm|No organizations found'),
    issuesButtonLabel: __('View issues'),
    errorText: __('Something went wrong. Please try again.'),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" class="gl-my-6" @dismiss="dismissError">
      <div>{{ $options.i18n.errorText }}</div>
    </gl-alert>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      :items="organizations"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    >
      <template #cell(id)="data">
        <gl-button
          v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
          data-testid="issues-link"
          icon="issues"
          :aria-label="$options.i18n.issuesButtonLabel"
          :href="getIssuesPath(groupIssuesPath, data.value)"
        />
      </template>
    </gl-table>
  </div>
</template>
