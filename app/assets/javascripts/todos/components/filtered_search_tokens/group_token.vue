<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import searchGroupsQuery from '../queries/search_groups.query.graphql';

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
      groups: this.config.initialGroups || [],
      loading: false,
    };
  },
  computed: {
    defaultGroups() {
      return this.config.defaultGroups || [];
    },
  },
  methods: {
    fetchGroups(search = '') {
      return this.$apollo
        .query({
          query: searchGroupsQuery,
          variables: { search },
        })
        .then(({ data }) => data.groups.nodes);
    },
    fetchGroupsBySearchTerm(search) {
      this.loading = true;
      this.fetchGroups(search)
        .then((response) => {
          this.groups = response;
        })
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
      return String(this.getGroupIdProperty(group));
    },
    displayValue(group) {
      return group?.fullName;
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
        :key="group.id"
        :value="getValue(group)"
      >
        {{ group.fullName }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
