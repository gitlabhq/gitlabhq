<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import organizationsQuery from '../graphql/organizations.query.graphql';
import OrganizationsList from './organizations_list.vue';

export default {
  name: 'OrganizationsView',
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading user organizations. Please refresh the page to try again.',
    ),
    emptyStateTitle: s__('Organization|Get started with organizations'),
    emptyStateDescription: s__(
      'Organization|Create an organization to contain all of your groups and projects.',
    ),
    emptyStateButtonText: s__('Organization|New organization'),
  },
  components: {
    GlLoadingIcon,
    OrganizationsList,
    GlEmptyState,
  },
  inject: ['newOrganizationUrl', 'organizationsEmptyStateSvgPath'],
  data() {
    return {
      organizations: [],
    };
  },
  apollo: {
    organizations: {
      query: organizationsQuery,
      update(data) {
        return data.currentUser.organizations.nodes;
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.organizations.loading;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <organizations-list
    v-else-if="organizations.length"
    :organizations="organizations"
    class="gl-border-t"
  />
  <gl-empty-state
    v-else
    :svg-height="144"
    :svg-path="organizationsEmptyStateSvgPath"
    :title="$options.i18n.emptyStateTitle"
    :description="$options.i18n.emptyStateDescription"
    :primary-button-link="newOrganizationUrl"
    :primary-button-text="$options.i18n.emptyStateButtonText"
  />
</template>
