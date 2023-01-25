<script>
import { GlDropdown, GlSearchBoxByType, GlDropdownItem, GlDropdownText } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import {
  I18N_NO_RESULTS_MESSAGE,
  I18N_PROJECT_HEADER,
  I18N_PROJECT_SEARCH_PLACEHOLDER,
} from '../constants';

export default {
  name: 'ProjectsDropdown',
  components: {
    GlDropdown,
    GlSearchBoxByType,
    GlDropdownItem,
    GlDropdownText,
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
    selectedProject() {
      return this.sortedProjects.find((project) => project.id === this.targetProjectId) || {};
    },
  },
  methods: {
    selectProject(project) {
      this.$emit('selectProject', project.id);
      this.filterTerm = project.name; // when we select a project, we want the dropdown to filter to the selected project
    },
    isSelected(selectedProject) {
      return selectedProject === this.selectedProject;
    },
    filterTermChanged(value) {
      this.filterTerm = value;
    },
  },
};
</script>
<template>
  <gl-dropdown :text="selectedProject.name" :header-text="$options.i18n.projectHeaderTitle">
    <gl-search-box-by-type
      :value="filterTerm"
      trim
      autocomplete="off"
      :placeholder="$options.i18n.projectSearchPlaceholder"
      data-testid="dropdown-search-box"
      @input="filterTermChanged"
    />
    <gl-dropdown-item
      v-for="project in filteredResults"
      :key="project.name"
      :name="project.name"
      :is-checked="isSelected(project)"
      is-check-item
      data-testid="dropdown-item"
      @click="selectProject(project)"
    >
      {{ project.name }}
    </gl-dropdown-item>
    <gl-dropdown-text v-if="!filteredResults.length" data-testid="empty-result-message">
      <span class="gl-text-gray-500">{{ $options.i18n.noResultsMessage }}</span>
    </gl-dropdown-text>
  </gl-dropdown>
</template>
