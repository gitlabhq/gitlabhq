<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { HR_DEFAULT_CLASSES } from '../constants';
import LanguageFilter from './language_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'BlobsFilters',
  components: {
    LanguageFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentScope']),
    ...mapState(['useSidebarNavigation', 'searchType']),
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
    <language-filter class="gl-mb-5" />
    <hr v-if="showDivider" :class="hrClasses" />
    <archived-filter class="gl-mb-5" />
  </filters-template>
</template>
