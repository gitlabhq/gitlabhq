<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import axios from 'axios';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

export default {
  name: 'EnvironmentToken',
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      environments: [],
      loading: true,
      search: '',
    };
  },
  computed: {
    filteredEnvironments() {
      const query = this.search.toLowerCase();
      return this.environments.filter((environment) => environment.toLowerCase().includes(query));
    },
  },
  methods: {
    getActiveEnvironment(environments, data) {
      return environments.find((environment) => environment.toLowerCase() === data.toLowerCase());
    },
    fetchEnvironments(search) {
      this.search = search;

      if (this.environments.length) return;

      axios
        .get(this.config.environmentsEndpoint)
        .then(({ data }) => {
          this.environments = data;
        })
        .catch(() => {
          createAlert({ message: __('There was a problem fetching environments.') });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :suggestions="filteredEnvironments"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveEnvironment"
    v-bind="$attrs"
    @fetch-suggestions="fetchEnvironments"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? activeTokenValue : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="environment in suggestions"
        :key="environment"
        :value="environment"
      >
        {{ environment }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
