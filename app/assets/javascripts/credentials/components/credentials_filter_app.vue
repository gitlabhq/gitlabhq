<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { TOKENS } from '../constants';
import { initializeValuesFromQuery } from '../utils';

export default {
  components: {
    GlFilteredSearch,
  },
  data() {
    return { tokens: initializeValuesFromQuery() };
  },
  computed: {
    availableTokens() {
      // Once SSH or GPG key is selected, discard the rest of the tokens
      if (this.hasKey()) {
        return TOKENS.filter(({ type }) => type === 'filter');
      }

      return TOKENS;
    },
  },
  methods: {
    change() {
      // Once SSH or GPG key is selected, discard the rest of the tokens
      if (this.hasKey()) {
        this.tokens = this.tokens.filter(({ type }) => type === 'filter');
      }
    },
    hasKey() {
      return this.tokens.some(
        ({ type, value }) => type === 'filter' && ['ssh_keys', 'gpg_keys'].includes(value.data),
      );
    },
    search(tokens) {
      const newParams = {};

      tokens?.forEach((token) => {
        if (typeof token === 'string') {
          newParams.search = token;
        } else if (['created', 'expires', 'last_used'].includes(token.type)) {
          const isBefore = token.value.operator === '<';
          const key = `${token.type}${isBefore ? '_before' : '_after'}`;
          newParams[key] = token.value.data;
        } else {
          newParams[token.type] = token.value.data;
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
    v-model="tokens"
    :placeholder="s__('CredentialsInventory|Search or filter credentials...')"
    :available-tokens="availableTokens"
    terms-as-tokens
    @submit="search"
    @input="change"
  />
</template>
