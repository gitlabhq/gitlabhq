<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';

import { TYPENAME_CRM_ORGANIZATION } from '~/graphql_shared/constants';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import searchCrmOrganizationsQuery from '../queries/search_crm_organizations.query.graphql';

import { OPTIONS_NONE_ANY } from '../constants';

import BaseToken from './base_token.vue';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      organizations: this.config.initialOrganizations || [],
      loading: false,
    };
  },
  computed: {
    defaultOrganizations() {
      return this.config.defaultOrganizations || OPTIONS_NONE_ANY;
    },
    namespace() {
      return this.config.isProject ? WORKSPACE_PROJECT : WORKSPACE_GROUP;
    },
  },
  methods: {
    getActiveOrganization(organizations, data) {
      return organizations.find((organization) => {
        return `${this.formatOrganizationId(organization)}` === data;
      });
    },
    fetchOrganizations(searchTerm) {
      let searchString = null;
      let searchId = null;
      if (isPositiveInteger(searchTerm)) {
        searchId = this.formatOrganizationGraphQLId(searchTerm);
      } else {
        searchString = searchTerm;
      }

      this.loading = true;

      this.$apollo
        .query({
          query: searchCrmOrganizationsQuery,
          variables: {
            fullPath: this.config.fullPath,
            searchString,
            searchIds: searchId ? [searchId] : null,
            isProject: this.config.isProject,
          },
        })
        .then(({ data }) => {
          this.organizations = this.config.isProject
            ? data[this.namespace]?.group.organizations.nodes
            : data[this.namespace]?.organizations.nodes;
        })
        .catch(() =>
          createAlert({
            message: __('There was a problem fetching CRM organizations.'),
          }),
        )
        .finally(() => {
          this.loading = false;
        });
    },
    formatOrganizationId(organization) {
      return `${getIdFromGraphQLId(organization.id)}`;
    },
    formatOrganizationGraphQLId(id) {
      return convertToGraphQLId(TYPENAME_CRM_ORGANIZATION, id);
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="organizations"
    :get-active-token-value="getActiveOrganization"
    :default-suggestions="defaultOrganizations"
    v-bind="$attrs"
    @fetch-suggestions="fetchOrganizations"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? activeTokenValue.name : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="organization in suggestions"
        :key="formatOrganizationId(organization)"
        :value="formatOrganizationId(organization)"
      >
        {{ organization.name }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
