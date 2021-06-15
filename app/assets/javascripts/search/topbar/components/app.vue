<script>
import { GlForm, GlSearchBoxByType, GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import GroupFilter from './group_filter.vue';
import ProjectFilter from './project_filter.vue';

export default {
  name: 'GlobalSearchTopbar',
  components: {
    GlForm,
    GlSearchBoxByType,
    GroupFilter,
    ProjectFilter,
    GlButton,
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
  methods: {
    ...mapActions(['applyQuery', 'setQuery']),
  },
};
</script>

<template>
  <gl-form class="search-page-form" @submit.prevent="applyQuery">
    <section class="gl-lg-display-flex gl-align-items-flex-end">
      <div class="gl-flex-grow-1 gl-mb-4 gl-lg-mb-0 gl-lg-mr-2">
        <label>{{ __('What are you searching for?') }}</label>
        <gl-search-box-by-type
          id="dashboard_search"
          v-model="search"
          name="search"
          :placeholder="__(`Search for projects, issues, etc.`)"
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
      <gl-button class="btn-search gl-lg-ml-2" category="primary" variant="confirm" type="submit"
        >{{ __('Search') }}
      </gl-button>
    </section>
  </gl-form>
</template>
