<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { DEFAULT_PER_PAGE } from '~/api';
import OrganizationsView from '~/organizations/shared/components/organizations_view.vue';
import currentUserOrganizationsQuery from '../../shared/graphql/queries/current_user_organizations.query.graphql';

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
        return this.pagination;
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
      <div class="gl-ml-auto">
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
