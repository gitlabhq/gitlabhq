<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
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
    };
  },
  computed: {
    disableRepoDropdown() {
      return this.projects === null;
    },
    filteredRepos() {
      const lowerCaseSearchTerm = this.searchTerm.toLowerCase();

      return this?.projects.filter(({ name }) => name.toLowerCase().includes(lowerCaseSearchTerm));
    },
    inputName() {
      return `${this.paramsName}_project_id`;
    },
  },
  methods: {
    onClick(project) {
      this.emitTargetProject(project);
    },
    emitTargetProject(project) {
      this.$emit('selectProject', { direction: this.paramsName, project });
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" :name="inputName" :value="selectedProject.id" />
    <gl-dropdown
      :text="selectedProject.name"
      :header-text="s__(`CompareRevisions|Select target project`)"
      class="gl-w-full gl-font-monospace gl-sm-pr-3"
      toggle-class="gl-min-w-0"
      :disabled="disableRepoDropdown"
    >
      <template #header>
        <gl-search-box-by-type v-if="!disableRepoDropdown" v-model.trim="searchTerm" />
      </template>
      <template v-if="!disableRepoDropdown">
        <gl-dropdown-item
          v-for="repo in filteredRepos"
          :key="repo.id"
          is-check-item
          :is-checked="selectedProject.id === repo.id"
          @click="onClick(repo)"
        >
          {{ repo.name }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>
  </div>
</template>
