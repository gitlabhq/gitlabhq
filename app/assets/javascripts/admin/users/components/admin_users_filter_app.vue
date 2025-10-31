<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import {
  getStandardTokenConfigs,
  getFilterTokenConfigs,
  ACCESS_LEVEL_OPTIONS,
} from 'ee_else_ce/admin/users/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import glLicensedFeaturesMixin from '~/vue_shared/mixins/gl_licensed_features_mixin';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import { initializeValuesFromQuery } from '../utils';

export default {
  components: { GlFilteredSearch },
  mixins: [glLicensedFeaturesMixin(), glFeatureFlagsMixin(), glAbilitiesMixin()],
  data() {
    const filterTokenConfigs = getFilterTokenConfigs(ACCESS_LEVEL_OPTIONS);
    const standardTokenConfigs = getStandardTokenConfigs({
      ...this.glLicensedFeatures,
      ...this.glFeatures,
      ...this.glAbilities,
    });
    const { tokenValues, sort } = initializeValuesFromQuery(
      filterTokenConfigs,
      standardTokenConfigs,
    );

    return { filterTokenConfigs, standardTokenConfigs, tokenValues, sort };
  },
  computed: {
    selectedFilterTokenConfig() {
      const selectedTypes = new Set(this.tokenValues.map(({ type }) => type));
      return this.filterTokenConfigs.find(({ type }) => selectedTypes.has(type));
    },
    availableTokenConfigs() {
      // Due to the way the search is implemented on the backend, only one filter token config can
      // be used at a time. If a filter token config is used, return only that config with the
      // standard configs. Otherwise, return all the token configs.
      return this.selectedFilterTokenConfig
        ? [this.selectedFilterTokenConfig, ...this.standardTokenConfigs]
        : [...this.filterTokenConfigs, ...this.standardTokenConfigs];
    },
  },
  methods: {
    search(tokens) {
      const newParams = {};

      tokens?.forEach((token) => {
        // If this is search text, set it as the search query.
        if (typeof token === 'string') {
          newParams.search_query = token;
        }
        // If this is the selected filter token, set the filter parameter.
        else if (token.type === this.selectedFilterTokenConfig?.type) {
          newParams.filter = token.value.data;
        }
        // Otherwise, it's a standard token. Set the parameter using the token type and its value.
        else {
          newParams[token.type] = token.value.data;
        }
      });

      if (this.sort) {
        newParams.sort = this.sort;
      }

      const newUrl = setUrlParams(newParams, { url: window.location.href, clearParams: true });
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
