<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SEARCH_TYPE_ADVANCED } from '~/search/sidebar/constants';
import ConfidentialityFilter from './confidentiality_filter/index.vue';
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
    ...mapGetters(['hasMissingProjectContext']),
    ...mapState(['searchType']),
    showLabelFilter() {
      return this.searchType === SEARCH_TYPE_ADVANCED;
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter class="gl-mb-5" />
    <confidentiality-filter class="gl-mb-5" />
    <label-filter v-if="showLabelFilter" class="gl-mb-5" />
    <archived-filter v-if="hasMissingProjectContext" class="gl-mb-5" />
  </filters-template>
</template>
