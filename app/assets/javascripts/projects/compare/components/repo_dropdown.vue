<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    paramsName: {
      type: String,
      required: true,
    },
    endpoint: {
      type: String,
      required: false,
      default: '',
    },
    selectedProject: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      selectedProjectId: this.selectedProject.id,
      projects: [],
      searchStr: '',
    };
  },
  computed: {
    isDropdownDisabled() {
      return this.paramsName === 'to';
    },
    inputName() {
      return `${this.paramsName}_project_id`;
    },
  },
  created() {
    if (!this.isDropdownDisabled) {
      this.fetchProjects();
    }
    this.debouncedProjectsSearch = debounce(this.fetchProjects, 500);
  },
  methods: {
    emitTargetProject(projectId) {
      if (this.isDropdownDisabled) return;
      const project = this.projects.find(({ value }) => value === projectId);
      this.$emit('selectProject', { direction: this.paramsName, project });
    },
    async fetchProjects() {
      if (!this.endpoint) return;

      this.isLoading = true;

      try {
        const { data } = await axios.get(this.endpoint, {
          params: { search: this.searchStr },
        });

        this.projects = data.map((p) => ({
          value: `${p.id}`,
          text: p.full_path.replace(/^\//, ''),
        }));
      } catch {
        createAlert({
          message: __('Error fetching data. Please try again.'),
          primaryButton: { text: __('Try again'), clickHandler: () => this.fetchProjects() },
        });
      }
      this.isLoading = false;
    },
    searchProjects(search) {
      this.searchStr = search;
      this.debouncedProjectsSearch();
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" :name="inputName" :value="selectedProjectId" />
    <gl-collapsible-listbox
      v-model="selectedProjectId"
      :toggle-text="selectedProject.text"
      :loading="isLoading"
      :header-text="s__(`CompareRevisions|Select target project`)"
      class="gl-font-monospace"
      toggle-class="gl-min-w-0"
      :disabled="isDropdownDisabled"
      :items="projects"
      block
      searchable
      @select="emitTargetProject"
      @search="searchProjects"
    />
  </div>
</template>
