<script>
import { GlSearchBoxByClick } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import GroupFilter from './group_filter.vue';
import ProjectFilter from './project_filter.vue';

export default {
  name: 'GlobalSearchTopbar',
  i18n: {
    searchPlaceholder: s__(`GlobalSearch|Search for projects, issues, etc.`),
    searchLabel: s__(`GlobalSearch|What are you searching for?`),
  },
  components: {
    GlSearchBoxByClick,
    GroupFilter,
    ProjectFilter,
  },
  props: {
    groupInitialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projectInitialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState(['query']),
    search: {
      get() {
        return this.query ? this.query.search : '';
      },
      set(value) {
        this.setQuery({ key: 'search', value });
      },
    },
    showFilters() {
      return !this.query.snippets || this.query.snippets === 'false';
    },
  },
  created() {
    this.preloadStoredFrequentItems();
  },
  methods: {
    ...mapActions(['applyQuery', 'setQuery', 'preloadStoredFrequentItems']),
  },
};
</script>

<template>
  <section class="search-page-form gl-lg-display-flex gl-align-items-flex-end">
    <div class="gl-flex-grow-1 gl-mb-4 gl-lg-mb-0 gl-lg-mr-2">
      <label>{{ $options.i18n.searchLabel }}</label>
      <gl-search-box-by-click
        id="dashboard_search"
        v-model="search"
        name="search"
        :placeholder="$options.i18n.searchPlaceholder"
        @submit="applyQuery"
      />
    </div>
    <div v-if="showFilters" class="gl-mb-4 gl-lg-mb-0 gl-lg-mx-2">
      <label class="gl-display-block">{{ __('Group') }}</label>
      <group-filter :initial-data="groupInitialData" />
    </div>
    <div v-if="showFilters" class="gl-mb-4 gl-lg-mb-0 gl-lg-mx-2">
      <label class="gl-display-block">{{ __('Project') }}</label>
      <project-filter :initial-data="projectInitialData" />
    </div>
  </section>
</template>
