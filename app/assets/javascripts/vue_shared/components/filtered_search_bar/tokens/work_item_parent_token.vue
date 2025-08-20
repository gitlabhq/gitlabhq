<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';

import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { OPTIONS_NONE_ANY } from '../constants';

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
      workItems: this.config.initialWorkItems || [],
      loading: false,
    };
  },
  computed: {
    idProperty() {
      return this.config.idProperty || 'iid';
    },
    defaultWorkItems() {
      return this.config.defaultWorkItems || OPTIONS_NONE_ANY;
    },
  },
  methods: {
    async fetchWorkItemsBySearchTerm() {
      // TODO: Implement fetch
    },
    getActiveWorkItem(workItems, data) {
      if (data && workItems.length) {
        return workItems.find((workItem) => this.getValue(workItem) === data);
      }
      return undefined;
    },
    getValue(workItem) {
      return workItem[this.idProperty];
    },
    displayValue(workItem) {
      return workItem?.title;
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
    :suggestions="workItems"
    :get-active-token-value="getActiveWorkItem"
    :default-suggestions="defaultWorkItems"
    search-by="title"
    :value-identifier="getValue"
    v-bind="$attrs"
    @fetch-suggestions="fetchWorkItemsBySearchTerm"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="workItem in suggestions"
        :key="workItem.id"
        :value="getValue(workItem)"
      >
        {{ workItem.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
