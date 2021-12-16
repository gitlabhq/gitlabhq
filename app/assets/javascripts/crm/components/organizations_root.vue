<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME } from '../constants';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';
import NewOrganizationForm from './new_organization_form.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTable,
    NewOrganizationForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canAdminCrmOrganization', 'groupFullPath', 'groupIssuesPath'],
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
    showNewForm() {
      return this.$route.name === NEW_ROUTE_NAME;
    },
    canCreateNew() {
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
    displayNewForm() {
      if (this.showNewForm) return;

      this.$router.push({ name: NEW_ROUTE_NAME });
    },
    hideNewForm(success) {
      if (success) this.$toast.show(this.$options.i18n.organizationAdded);

      this.$router.replace({ name: INDEX_ROUTE_NAME });
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
    title: s__('Crm|Customer Relations Organizations'),
    newOrganization: s__('Crm|New organization'),
    errorText: __('Something went wrong. Please try again.'),
    organizationAdded: s__('Crm|Organization has been added'),
  },
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
        v-if="canCreateNew"
        class="gl-display-none gl-md-display-flex gl-align-items-center gl-justify-content-end"
      >
        <gl-button variant="confirm" data-testid="new-organization-button" @click="displayNewForm">
          {{ $options.i18n.newOrganization }}
        </gl-button>
      </div>
    </div>
    <new-organization-form v-if="showNewForm" :drawer-open="showNewForm" @close="hideNewForm" />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      class="gl-mt-5"
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
