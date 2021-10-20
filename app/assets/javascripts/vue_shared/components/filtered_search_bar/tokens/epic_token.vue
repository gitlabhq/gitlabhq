<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import { DEFAULT_NONE_ANY, FILTER_NONE_ANY, OPERATOR_IS_NOT } from '../constants';
import searchEpicsQuery from '../queries/search_epics.query.graphql';

import BaseToken from './base_token.vue';

export default {
  prefix: '&',
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
      epics: this.config.initialEpics || [],
      loading: false,
    };
  },
  computed: {
    idProperty() {
      return this.config.idProperty || 'iid';
    },
    currentValue() {
      const epicIid = Number(this.value.data);
      if (epicIid) {
        return epicIid;
      }
      return this.value.data;
    },
    defaultEpics() {
      return this.config.defaultEpics || DEFAULT_NONE_ANY;
    },
    availableDefaultEpics() {
      if (this.value.operator === OPERATOR_IS_NOT) {
        return this.defaultEpics.filter(
          (suggestion) => !FILTER_NONE_ANY.includes(suggestion.value),
        );
      }
      return this.defaultEpics;
    },
  },
  methods: {
    fetchEpics(search = '') {
      return this.$apollo
        .query({
          query: searchEpicsQuery,
          variables: { fullPath: this.config.fullPath, search },
        })
        .then(({ data }) => data.group?.epics.nodes);
    },
    fetchEpicsBySearchTerm(search) {
      this.loading = true;
      this.fetchEpics(search)
        .then((response) => {
          this.epics = Array.isArray(response) ? response : response?.data;
        })
        .catch(() => createFlash({ message: __('There was a problem fetching epics.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    getActiveEpic(epics, data) {
      if (data && epics.length) {
        return epics.find((epic) => this.getValue(epic) === data);
      }
      return undefined;
    },
    getValue(epic) {
      return this.getEpicIdProperty(epic).toString();
    },
    displayValue(epic) {
      return `${this.$options.prefix}${this.getEpicIdProperty(epic)}${this.$options.separator}${
        epic?.title
      }`;
    },
    getEpicIdProperty(epic) {
      return getIdFromGraphQLId(epic[this.idProperty]);
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
    :suggestions="epics"
    :get-active-token-value="getActiveEpic"
    :default-suggestions="availableDefaultEpics"
    :recent-suggestions-storage-key="config.recentSuggestionsStorageKey"
    search-by="title"
    @fetch-suggestions="fetchEpicsBySearchTerm"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="epic in suggestions"
        :key="epic.id"
        :value="getValue(epic)"
      >
        {{ epic.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
