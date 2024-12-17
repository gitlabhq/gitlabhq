<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import OrganizationsView from '~/organizations/shared/components/organizations_view.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';
import organizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';

export default {
  name: 'AdminOrganizationsIndexApp',
  i18n: {
    pageTitle: __('Organizations'),
    newOrganization: s__('Organization|New organization'),
    errorMessage: s__(
      'Organization|An error occurred loading organizations. Please refresh the page to try again.',
    ),
  },
  components: { GlButton, OrganizationsView },
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
      query: organizationsQuery,
      variables() {
        return this.pagination;
      },
      update(data) {
        return data.organizations;
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
  <div class="gl-py-6">
    <div v-if="showHeader" class="gl-mb-5 gl-flex gl-items-center gl-justify-between">
      <h1 class="gl-m-0 gl-text-size-h-display">{{ $options.i18n.pageTitle }}</h1>
      <gl-button v-if="canCreateOrganization" :href="newOrganizationUrl" variant="confirm">{{
        $options.i18n.newOrganization
      }}</gl-button>
    </div>
    <organizations-view
      :organizations="organizations"
      :loading="loading"
      @next="onNext"
      @prev="onPrev"
    />
  </div>
</template>
