<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { DEFAULT_PER_PAGE } from '~/api';
import OrganizationsView from '~/organizations/shared/components/organizations_view.vue';
import { ORGANIZATION_STATE_ACTIVE } from '~/organizations/shared/constants';
import currentUserOrganizationsQuery from '../../shared/graphql/queries/current_user_organizations.query.graphql';

export default {
  name: 'OrganizationsIndexApp',
  i18n: {
    organizations: __('Organizations'),
    newOrganization: s__('Organization|New organization'),
    claimOrg: s__('Organization|Claim your org'),
    errorMessage: s__(
      'Organization|An error occurred loading user organizations. Please refresh the page to try again.',
    ),
  },
  components: {
    GlButton,
    OrganizationsView,
  },
  inject: ['newOrganizationUrl', 'canCreateOrganization'],
  data() {
    return {
      organizations: {},
      pagination: {
        first: DEFAULT_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
    };
  },
  apollo: {
    organizations: {
      query: currentUserOrganizationsQuery,
      variables() {
        return {
          ...this.pagination,
          // On gitlab.com the "Default" organization is a legacy container for resources that do not yet have their own organization.
          // We want to exclude it from the list to avoid confusion.
          // On self-managed and dedicated the `Default` organization is the only organization on the instance and can be used.
          excludeDefault: Boolean(window.gon.dot_com),
          state: ORGANIZATION_STATE_ACTIVE,
        };
      },
      update(data) {
        return data.currentUser.organizations;
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    showHeader() {
      return this.loading || this.organizations.nodes?.length;
    },
    loading() {
      return this.$apollo.queries.organizations.loading;
    },
  },
  methods: {
    onNext(endCursor) {
      this.pagination = {
        first: DEFAULT_PER_PAGE,
        after: endCursor,
        last: null,
        before: null,
      };
    },
    onPrev(startCursor) {
      this.pagination = {
        first: null,
        after: null,
        last: DEFAULT_PER_PAGE,
        before: startCursor,
      };
    },
  },
};
</script>

<template>
  <section>
    <div v-if="showHeader" class="gl-flex gl-items-center">
      <h1 class="gl-my-4 gl-text-size-h-display">{{ $options.i18n.organizations }}</h1>
      <div class="gl-ml-auto gl-flex gl-gap-2">
        <gl-button v-if="canCreateOrganization" :href="newOrganizationUrl" variant="confirm">{{
          $options.i18n.newOrganization
        }}</gl-button>
      </div>
    </div>
    <organizations-view
      :organizations="organizations"
      :loading="loading"
      @next="onNext"
      @prev="onPrev"
    />
  </section>
</template>
