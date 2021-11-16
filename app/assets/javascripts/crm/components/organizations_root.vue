<script>
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__, __ } from '~/locale';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlTable,
  },
  inject: ['groupFullPath'],
  data() {
    return { organizations: [] };
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
      error(error) {
        createFlash({
          message: __('Something went wrong. Please try again.'),
          error,
          captureError: true,
        });
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
  },
  fields: [
    { key: 'name', sortable: true },
    { key: 'defaultRate', sortable: true },
    { key: 'description', sortable: true },
  ],
  i18n: {
    emptyText: s__('Crm|No organizations found'),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      :items="organizations"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    />
  </div>
</template>
