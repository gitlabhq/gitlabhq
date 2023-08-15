<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import { debounce, uniqBy } from 'lodash';
import {
  I18N_NO_RESULTS_MESSAGE,
  I18N_PROJECT_HEADER,
  I18N_PROJECT_SEARCH_PLACEHOLDER,
} from '../constants';

export default {
  name: 'ProjectsDropdown',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    noResultsMessage: I18N_NO_RESULTS_MESSAGE,
    projectHeaderTitle: I18N_PROJECT_HEADER,
    projectSearchPlaceholder: I18N_PROJECT_SEARCH_PLACEHOLDER,
  },
  data() {
    return {
      filterTerm: '',
    };
  },
  computed: {
    ...mapGetters(['sortedProjects']),
    ...mapState(['targetProjectId']),
    filteredResults() {
      const lowerCasedFilterTerm = this.filterTerm.toLowerCase();
      return this.sortedProjects.filter((project) =>
        project.name.toLowerCase().includes(lowerCasedFilterTerm),
      );
    },
    listboxItems() {
      const selectedItem = { value: this.selectedProject.id, text: this.selectedProject.name };
      const transformedList = this.filteredResults.map(({ id, name }) => ({
        value: id,
        text: name,
      }));

      if (this.filterTerm) {
        return transformedList;
      }

      // Add selected item to top of list if not searching
      return uniqBy([selectedItem].concat(transformedList), 'value');
    },
    selectedProject() {
      return this.sortedProjects.find((project) => project.id === this.targetProjectId) || {};
    },
  },
  methods: {
    selectProject(value) {
      this.$emit('input', value);
    },
    debouncedSearch: debounce(function debouncedSearch(value) {
      this.filterTerm = value.trim();
    }, 250),
  },
};
</script>
<template>
  <gl-collapsible-listbox
    class="gl-max-w-full"
    :header-text="$options.i18n.projectHeaderTitle"
    :items="listboxItems"
    searchable
    :search-placeholder="$options.i18n.projectSearchPlaceholder"
    :selected="selectedProject.id"
    :toggle-text="selectedProject.name"
    toggle-class="gl-w-full"
    :no-results-text="$options.i18n.noResultsMessage"
    @search="debouncedSearch"
    @select="selectProject"
  />
</template>
