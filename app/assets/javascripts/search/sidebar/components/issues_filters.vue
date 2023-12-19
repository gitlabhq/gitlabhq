<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SEARCH_TYPE_ADVANCED } from '../constants';
import { confidentialFilterData } from './confidentiality_filter/data';
import { statusFilterData } from './status_filter/data';
import ConfidentialityFilter from './confidentiality_filter/index.vue';
import { labelFilterData } from './label_filter/data';
import { archivedFilterData } from './archived_filter/data';
import LabelFilter from './label_filter/index.vue';
import StatusFilter from './status_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';

import FiltersTemplate from './filters_template.vue';

export default {
  name: 'IssuesFilters',
  components: {
    StatusFilter,
    ConfidentialityFilter,
    LabelFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentScope']),
    ...mapState(['searchType']),
    showConfidentialityFilter() {
      return Object.values(confidentialFilterData.scopes).includes(this.currentScope);
    },
    showStatusFilter() {
      return Object.values(statusFilterData.scopes).includes(this.currentScope);
    },
    showLabelFilter() {
      return (
        Object.values(labelFilterData.scopes).includes(this.currentScope) &&
        this.searchType === SEARCH_TYPE_ADVANCED
      );
    },
    showArchivedFilter() {
      return archivedFilterData.scopes.includes(this.currentScope);
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter v-if="showStatusFilter" class="gl-mb-5" />
    <confidentiality-filter v-if="showConfidentialityFilter" class="gl-mb-5" />
    <label-filter v-if="showLabelFilter" class="gl-mb-5" />
    <archived-filter v-if="showArchivedFilter" class="gl-mb-5" />
  </filters-template>
</template>
