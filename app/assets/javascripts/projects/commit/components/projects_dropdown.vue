<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
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
      filterTerm: this.value,
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
      return this.filteredResults.map(({ id, name }) => ({ value: id, text: name }));
    },
    selectedProject() {
      return this.sortedProjects.find((project) => project.id === this.targetProjectId) || {};
    },
  },
  methods: {
    selectProject(value) {
      this.$emit('selectProject', value);

      // when we select a project, we want the dropdown to filter to the selected project
      const project = this.listboxItems.find((x) => x.value === value);
      this.filterTerm = project?.text || '';
    },
    filterTermChanged(value) {
      this.filterTerm = value;
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :header-text="$options.i18n.projectHeaderTitle"
    :items="listboxItems"
    searchable
    :search-placeholder="$options.i18n.projectSearchPlaceholder"
    :selected="selectedProject.id"
    :toggle-text="selectedProject.name"
    :no-results-text="$options.i18n.noResultsMessage"
    @search="filterTermChanged"
    @select="selectProject"
  />
</template>
