<script>
import { GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import getGroupNamesByIdsQuery from '~/ci/catalog/graphql/queries/get_groups_by_ids.query.graphql';

export default {
  name: 'GroupToken',
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
    GlIcon,
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
    const initialIds = [this.value.data].flat().filter(Boolean);
    return {
      groups: [],
      allGroups: [],
      initialGroups: [],
      searchTerm: null,
      initialIds,
    };
  },
  apollo: {
    initialGroups: {
      query: getGroupNamesByIdsQuery,
      variables() {
        return {
          ids: this.initialIds.map((id) => convertToGraphQLId(TYPENAME_GROUP, id)),
        };
      },
      skip() {
        return !this.initialIds.length;
      },
      update(data) {
        return this.mapGroupNodes(data?.groups?.nodes);
      },
      result({ data }) {
        if (!data?.groups?.nodes) return;
        this.updateAllGroups(this.initialGroups);
      },
      error() {
        createAlert({ message: s__('CiCatalog|There was an error fetching groups.') });
      },
    },
    groups: {
      query: groupsAutocompleteQuery,
      variables() {
        return { search: this.searchTerm };
      },
      skip() {
        return this.searchTerm === null;
      },
      update(data) {
        return this.mapGroupNodes(data?.groups?.nodes);
      },
      result({ data }) {
        if (!data?.groups?.nodes) return;
        this.updateAllGroups(this.groups);
      },
      error() {
        createAlert({ message: s__('CiCatalog|There was an error fetching groups.') });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.groups.loading;
    },
    groupNameMap() {
      return Object.fromEntries(this.allGroups.map((g) => [g.value, g.text]));
    },
    suggestions() {
      return this.searchTerm === null ? this.initialGroups : this.groups;
    },
  },
  methods: {
    mapGroupNodes(nodes) {
      return (nodes || []).map((group) => ({
        value: String(getIdFromGraphQLId(group.id)),
        text: group.fullName,
      }));
    },
    updateAllGroups(groups) {
      groups.forEach((group) => {
        if (!this.allGroups.some((g) => g.value === group.value)) {
          this.allGroups.push(group);
        }
      });
    },
    getActiveTokenValue(suggestions, data) {
      return (
        suggestions.find((s) => s.value === data) || this.allGroups.find((g) => g.value === data)
      );
    },
    getDisplayValue(selectedTokens) {
      return selectedTokens.map((id) => this.groupNameMap[id] || id).join(', ');
    },
  },
};
</script>

<template>
  <base-token
    v-bind="$attrs"
    :config="config"
    :value="value"
    :active="active"
    :suggestions="suggestions"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveTokenValue"
    v-on="$listeners"
    @fetch-suggestions="searchTerm = $event"
  >
    <template #view="{ viewTokenProps: { selectedTokens } }">
      <template v-if="selectedTokens.length > 0">{{ getDisplayValue(selectedTokens) }}</template>
    </template>
    <template #suggestions-list="{ suggestions: shownSuggestions, selections = [] }">
      <gl-filtered-search-suggestion
        v-for="group in shownSuggestions"
        :key="group.value"
        :value="group.value"
      >
        <div
          class="gl-flex gl-items-center"
          :class="{ 'gl-pl-6': !selections.includes(group.value) }"
        >
          <gl-icon
            v-if="selections.includes(group.value)"
            name="check"
            class="gl-mr-3 gl-shrink-0"
            variant="subtle"
          />
          {{ group.text }}
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
