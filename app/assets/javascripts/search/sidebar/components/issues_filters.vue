<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { HR_DEFAULT_CLASSES } from '../constants/index';
import { confidentialFilterData } from './confidentiality_filter/data';
import { statusFilterData } from './status_filter/data';
import ConfidentialityFilter from './confidentiality_filter/index.vue';
import { labelFilterData } from './label_filter/data';
import LabelFilter from './label_filter/index.vue';
import StatusFilter from './status_filter/index.vue';

import FiltersTemplate from './filters_template.vue';

export default {
  name: 'IssuesFilters',
  components: {
    StatusFilter,
    ConfidentialityFilter,
    LabelFilter,
    FiltersTemplate,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentScope']),
    ...mapState(['useSidebarNavigation']),
    showConfidentialityFilter() {
      return Object.values(confidentialFilterData.scopes).includes(this.currentScope);
    },
    showStatusFilter() {
      return Object.values(statusFilterData.scopes).includes(this.currentScope);
    },
    showLabelFilter() {
      return (
        Object.values(labelFilterData.scopes).includes(this.currentScope) &&
        this.glFeatures.searchIssueLabelAggregation
      );
    },
    showDivider() {
      return !this.useSidebarNavigation;
    },
    hrClasses() {
      return [...HR_DEFAULT_CLASSES, 'gl-display-none', 'gl-md-display-block'];
    },
  },
};
</script>

<template>
  <filters-template>
    <status-filter v-if="showStatusFilter" class="gl-mb-5" />
    <hr v-if="showConfidentialityFilter && showDivider" :class="hrClasses" />
    <confidentiality-filter v-if="showConfidentialityFilter" class="gl-mb-5" />
    <hr v-if="showLabelFilter && showDivider" :class="hrClasses" />
    <label-filter v-if="showLabelFilter" />
  </filters-template>
</template>
