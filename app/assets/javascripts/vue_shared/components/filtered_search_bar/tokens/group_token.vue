<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { pick } from 'lodash';
import { createAlert } from '~/alert';
import searchGroupsQuery from '~/boards/graphql/sub_groups.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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
          variables: { fullPath: this.config.fullPath, search },
        })
        .then(({ data }) => data.group);
    },
    fetchGroupsBySearchTerm(search) {
      this.loading = true;
      this.fetchGroups(search)
        .then((response) => {
          const parentGroup = pick(response, ['id', 'name', 'fullName', 'fullPath']) || {};
          this.groups = [parentGroup, ...(response?.descendantGroups?.nodes || [])];
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
      return group.fullPath;
    },
    displayValue(group) {
      const prefix = this.config.skipIdPrefix
        ? ''
        : `${this.getGroupIdProperty(group)}${this.$options.separator}`;
      return `${prefix}${group?.fullName}`;
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
        :key="group.id"
        :value="getValue(group)"
      >
        {{ group.fullName }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
