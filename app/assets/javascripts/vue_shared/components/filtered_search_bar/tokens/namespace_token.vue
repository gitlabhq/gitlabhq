<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import API from '~/api';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { camelizeKeys } from '~/lib/utils/object_utils';
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
      namespaces: [],
      loading: true,
    };
  },
  methods: {
    getActiveNamespace(namespaces, selected) {
      return namespaces.find((namespace) => namespace.fullPath === selected);
    },
    setNamespaces(namespaces) {
      this.namespaces = namespaces.map(camelizeKeys);
    },
    fetchNamespaces(searchTerm) {
      this.loading = true;

      API.namespaces(searchTerm, { full_path_search: true }, this.setNamespaces)
        .catch(() => createAlert({ message: __('There was a problem fetching namespaces.') }))
        .finally(() => {
          this.loading = false;
        });
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
    :suggestions="namespaces"
    :get-active-token-value="getActiveNamespace"
    v-bind="$attrs"
    v-on="$listeners"
    @fetch-suggestions="fetchNamespaces"
  >
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="suggestion in suggestions"
        :key="suggestion.id"
        :value="suggestion.fullPath"
      >
        {{ suggestion.fullPath }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
