<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { TOKENS, TOKEN_TYPES } from '../constants';
import { initializeValues } from '../utils';

export default {
  name: 'AdminUsersFilterApp',
  components: {
    GlFilteredSearch,
  },
  data() {
    return {
      values: initializeValues(),
    };
  },
  computed: {
    availableTokens() {
      // Once a token is selected, discard the rest
      const tokenType = this.values.find(({ type }) => TOKEN_TYPES.includes(type))?.type;

      if (tokenType) {
        return TOKENS.filter(({ type }) => type === tokenType);
      }

      return TOKENS;
    },
  },
  methods: {
    handleSearch(filters) {
      const newParams = {};

      filters?.forEach((filter) => {
        if (typeof filter === 'string') {
          newParams.search_query = filter;
        } else {
          newParams.filter = filter.value.data;
        }
      });

      const newUrl = setUrlParams(newParams, window.location.href, true);
      visitUrl(newUrl);
    },
  },
};
</script>

<template>
  <gl-filtered-search
    v-model="values"
    :placeholder="s__('AdminUsers|Search by name, email, or username')"
    :available-tokens="availableTokens"
    class="gl-mb-4"
    terms-as-tokens
    @submit="handleSearch"
  />
</template>
