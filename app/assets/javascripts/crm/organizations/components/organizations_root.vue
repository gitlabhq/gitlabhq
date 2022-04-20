<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { EDIT_ROUTE_NAME, NEW_ROUTE_NAME } from '../../constants';
import getGroupOrganizationsQuery from './graphql/get_group_organizations.query.graphql';

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
  inject: ['canAdminCrmOrganization', 'groupFullPath', 'groupIssuesPath'],
  data() {
    return {
      organizations: [],
      error: false,
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
    canAdmin() {
      return parseBoolean(this.canAdminCrmOrganization);
    },
  },
  methods: {
    extractOrganizations(data) {
      const organizations = data?.group?.organizations?.nodes || [];
      return organizations.slice().sort((a, b) => a.name.localeCompare(b.name));
    },
    getIssuesPath(path, value) {
      return `${path}?scope=all&state=opened&crm_organization_id=${value}`;
    },
    getEditRoute(id) {
      return { name: this.$options.EDIT_ROUTE_NAME, params: { id } };
    },
  },
  fields: [
    { key: 'name', sortable: true },
    { key: 'defaultRate', sortable: true },
    { key: 'description', sortable: true },
    {
      key: 'id',
      label: '',
      formatter: (id) => {
        return getIdFromGraphQLId(id);
      },
    },
  ],
  i18n: {
    emptyText: s__('Crm|No organizations found'),
    issuesButtonLabel: __('View issues'),
    editButtonLabel: __('Edit'),
    title: s__('Crm|Customer relations organizations'),
    newOrganization: s__('Crm|New organization'),
    errorText: __('Something went wrong. Please try again.'),
  },
  EDIT_ROUTE_NAME,
  NEW_ROUTE_NAME,
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" class="gl-mt-6" @dismiss="error = false">
      {{ $options.i18n.errorText }}
    </gl-alert>
    <div
      class="gl-display-flex gl-align-items-baseline gl-flex-direction-row gl-justify-content-space-between gl-mt-6"
    >
      <h2 class="gl-font-size-h2 gl-my-0">
        {{ $options.i18n.title }}
      </h2>
      <div
        v-if="canAdmin"
        class="gl-display-none gl-md-display-flex gl-align-items-center gl-justify-content-end"
      >
        <router-link :to="{ name: $options.NEW_ROUTE_NAME }">
          <gl-button variant="confirm" data-testid="new-organization-button">
            {{ $options.i18n.newOrganization }}
          </gl-button>
        </router-link>
      </div>
    </div>
    <router-view />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      class="gl-mt-5"
      :items="organizations"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    >
      <template #cell(id)="{ value: id }">
        <gl-button
          v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
          class="gl-mr-3"
          data-testid="issues-link"
          icon="issues"
          :aria-label="$options.i18n.issuesButtonLabel"
          :href="getIssuesPath(groupIssuesPath, id)"
        />
        <router-link :to="getEditRoute(id)">
          <gl-button
            v-if="canAdmin"
            v-gl-tooltip.hover.bottom="$options.i18n.editButtonLabel"
            data-testid="edit-organization-button"
            icon="pencil"
            :aria-label="$options.i18n.editButtonLabel"
          />
        </router-link>
      </template>
    </gl-table>
  </div>
</template>
