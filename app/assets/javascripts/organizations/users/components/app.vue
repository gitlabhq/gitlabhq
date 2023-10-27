<script>
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import organizationUsersQuery from '../graphql/organization_users.query.graphql';

export default {
  name: 'OrganizationsUsersApp',
  i18n: {
    users: __('Users'),
    loadingPlaceholder: __('Loading'),
    errorMessage: s__(
      'Organization|An error occurred loading the organization users. Please refresh the page to try again.',
    ),
  },
  inject: ['organizationGid'],
  data() {
    return {
      users: [],
    };
  },
  apollo: {
    users: {
      query: organizationUsersQuery,
      variables() {
        return { id: this.organizationGid };
      },
      update(data) {
        return data.organization.organizationUsers.nodes;
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.users.loading;
    },
  },
};
</script>

<template>
  <section>
    <h1 class="gl-my-4 gl-font-size-h-display">{{ $options.i18n.users }}</h1>
    <template v-if="loading">
      {{ $options.i18n.loadingPlaceholder }}
    </template>
    <div data-testid="organization-users">{{ users }}</div>
  </section>
</template>
