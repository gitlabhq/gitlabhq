<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { TOKENS } from '../constants';
import { initializeValuesFromQuery } from '../utils';

const TOKEN_TYPES = TOKENS.map(({ type }) => type);

export default {
  name: 'AdminUsersFilterApp',
  components: {
    GlFilteredSearch,
  },
  data() {
    const { tokens, sort } = initializeValuesFromQuery();

    return {
      tokens,
      sort,
    };
  },
  computed: {
    availableTokens() {
      // Once a token is selected, discard the rest
      const token = this.tokens.find(({ type }) => TOKEN_TYPES.includes(type));

      if (token) {
        return TOKENS.filter(({ type }) => type === token.type);
      }

      return TOKENS;
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
    v-model="tokens"
    :placeholder="s__('AdminUsers|Search by name, email, or username')"
    :available-tokens="availableTokens"
    terms-as-tokens
    @submit="search"
  />
</template>
