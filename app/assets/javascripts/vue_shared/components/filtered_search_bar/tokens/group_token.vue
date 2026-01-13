<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { pick } from 'lodash';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import searchGroupsQuery from '~/boards/graphql/sub_groups.query.graphql';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

export default {
  separator: '::',
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
      groups: this.config.initialGroups || [],
      // Avoids the flash of empty dropdown, assume loading until not.
      loading: true,
    };
  },
  computed: {
    defaultGroups() {
      return this.config.defaultGroups || [];
    },
  },
  methods: {
    fetchSubGroups(search = '') {
      return this.$apollo
        .query({
          query: searchGroupsQuery,
          variables: { fullPath: this.config.fullPath, search },
        })
        .then(({ data }) => data.group)
        .then((response) => {
          const parentGroup = pick(response, ['id', 'name', 'fullName', 'fullPath']) || {};
          this.groups = [parentGroup, ...(response?.descendantGroups?.nodes || [])];
        });
    },
    fetchAllGroups(search = '') {
      return this.$apollo
        .query({
          query: groupsAutocompleteQuery,
          variables: { search },
        })
        .then((response) => {
          this.groups = response.data.groups.nodes;
        });
    },
    fetchGroupsBySearchTerm(search) {
      this.loading = true;
      const fetchGroupsPromise =
        this.config.tokenType === __('All') ? this.fetchAllGroups : this.fetchSubGroups;
      fetchGroupsPromise(search)
        .catch(() => createAlert({ message: __('There was a problem fetching groups.') }))
        .finally(() => {
          this.loading = false;
        });
    },

    getActiveGroup(groups, data) {
      if (data && groups.length) {
        return groups.find((group) => this.getValue(group) === data);
      }
      return undefined;
    },
    getValue(group) {
      return group.fullPath;
    },
    displayValue(group) {
      const prefix = this.config.skipIdPrefix
        ? ''
        : `${this.getGroupIdProperty(group)}${this.$options.separator}`;
      return `${prefix}${group?.fullPath}`;
    },
    getGroupIdProperty(group) {
      return getIdFromGraphQLId(group.id);
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
    :suggestions="groups"
    :get-active-token-value="getActiveGroup"
    :default-suggestions="defaultGroups"
    search-by="title"
    :value-identifier="getValue"
    v-bind="$attrs"
    @fetch-suggestions="fetchGroupsBySearchTerm"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="group in suggestions"
        :key="displayValue(group)"
        :value="getValue(group)"
      >
        {{ group.fullName }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
