<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { TOKEN_CONFIGS } from 'ee_else_ce/admin/users/constants';
import { initializeValuesFromQuery } from '../utils';

export default {
  components: { GlFilteredSearch },
  data() {
    const { tokenValues, sort } = initializeValuesFromQuery();

    return {
      tokenValues,
      sort,
    };
  },
  computed: {
    selectedTokenConfig() {
      const selectedTypes = new Set(this.tokenValues.map(({ type }) => type));
      return TOKEN_CONFIGS.find(({ type }) => selectedTypes.has(type));
    },
    availableTokenConfigs() {
      // If there's a selected filter, return only that filter. Due to the way the search is
      // implemented on the backend, only one filter can be used at a time.
      return this.selectedTokenConfig ? [this.selectedTokenConfig] : TOKEN_CONFIGS;
    },
  },
  methods: {
    search(tokens) {
      const newParams = {};

      tokens?.forEach((token) => {
        if (typeof token === 'string') {
          newParams.search_query = token;
        } else {
          newParams.filter = token.value.data;
        }
      });

      if (this.sort) {
        newParams.sort = this.sort;
      }

      const newUrl = setUrlParams(newParams, window.location.href, true);
      visitUrl(newUrl);
    },
  },
};
</script>

<template>
  <gl-filtered-search
    v-model="tokenValues"
    :placeholder="s__('AdminUsers|Search by name, email, or username')"
    :available-tokens="availableTokenConfigs"
    terms-as-tokens
    @submit="search"
  />
</template>
