<script>
import { GlCollapsibleListbox } from '@gitlab/ui';

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    paramsName: {
      type: String,
      required: true,
    },
    projects: {
      type: Array,
      required: false,
      default: null,
    },
    selectedProject: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedProjectId: this.selectedProject.id,
    };
  },
  computed: {
    disableRepoDropdown() {
      return this.projects === null;
    },
    filteredRepos() {
      if (this.disableRepoDropdown) return [];

      const lowerCaseSearchTerm = this.searchTerm.toLowerCase();
      return this.projects
        .filter(({ name }) => name.toLowerCase().includes(lowerCaseSearchTerm))
        .map((project) => ({ text: project.name, value: project.id }));
    },
    inputName() {
      return `${this.paramsName}_project_id`;
    },
  },
  methods: {
    emitTargetProject(projectId) {
      if (this.disableRepoDropdown) return;
      const project = this.projects.find(({ id }) => id === projectId);
      this.$emit('selectProject', { direction: this.paramsName, project });
    },
    onSearch(searchTerm) {
      this.searchTerm = searchTerm;
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" :name="inputName" :value="selectedProjectId" />
    <gl-collapsible-listbox
      v-model="selectedProjectId"
      :toggle-text="selectedProject.name"
      :header-text="s__(`CompareRevisions|Select target project`)"
      class="gl-font-monospace"
      toggle-class="gl-min-w-0"
      :disabled="disableRepoDropdown"
      :items="filteredRepos"
      block
      searchable
      @select="emitTargetProject"
      @search="onSearch"
    />
  </div>
</template>
