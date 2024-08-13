<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

export default {
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
      branches: this.config.initialBranches || [],
      loading: false,
    };
  },
  computed: {
    defaultBranches() {
      return this.config.defaultBranches || [];
    },
  },
  methods: {
    getActiveBranch(branches, data) {
      return branches.find((branch) => branch.name.toLowerCase() === data.toLowerCase());
    },
    fetchBranches(searchTerm) {
      this.loading = true;
      this.config
        .fetchBranches(searchTerm)
        .then(({ data }) => {
          this.branches = data;
        })
        .catch(() => {
          createAlert({ message: __('There was a problem fetching branches.') });
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
    :default-suggestions="defaultBranches"
    :suggestions="branches"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveBranch"
    v-bind="$attrs"
    @fetch-suggestions="fetchBranches"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? activeTokenValue.name : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="branch in suggestions"
        :key="branch.id"
        :value="branch.name"
      >
        <div class="gl-flex">
          <span class="gl-mr-3 gl-inline-block gl-p-3"></span>
          {{ branch.name }}
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
