<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import organizationsQuery from '../graphql/organizations.query.graphql';
import OrganizationsView from './organizations_view.vue';

export default {
  name: 'OrganizationsIndexApp',
  i18n: {
    organizations: __('Organizations'),
    newOrganization: s__('Organization|New organization'),
    errorMessage: s__(
      'Organization|An error occurred loading user organizations. Please refresh the page to try again.',
    ),
  },
  components: {
    GlButton,
    OrganizationsView,
  },
  inject: ['newOrganizationUrl'],
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
    showHeader() {
      return this.loading || this.organizations.length;
    },
    loading() {
      return this.$apollo.queries.organizations.loading;
    },
  },
};
</script>

<template>
  <section>
    <div v-if="showHeader" class="gl-display-flex gl-align-items-center">
      <h1 class="gl-my-4 gl-font-size-h-display">{{ $options.i18n.organizations }}</h1>
      <div class="gl-ml-auto">
        <gl-button :href="newOrganizationUrl" variant="confirm">{{
          $options.i18n.newOrganization
        }}</gl-button>
      </div>
    </div>
    <organizations-view :organizations="organizations" :loading="loading" />
  </section>
</template>
