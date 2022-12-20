<script>
import { GlListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/flash';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlListbox,
  },
  inject: {
    targetProjectsPath: {
      type: String,
      required: true,
    },
    currentProject: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentProject: this.currentProject,
      selected: this.currentProject.value,
      isLoading: false,
      projects: [],
    };
  },
  methods: {
    async fetchProjects(search = '') {
      this.isLoading = true;

      try {
        const { data } = await axios.get(this.targetProjectsPath, {
          params: { search },
        });

        this.projects = data.map((p) => ({
          value: `${p.id}`,
          text: p.full_path.replace(/^\//, ''),
          refsUrl: p.refs_url,
        }));
        this.isLoading = false;
      } catch {
        createAlert({
          message: __('Error fetching target projects. Please try again.'),
          primaryButton: { text: __('Try again'), clickHandler: () => this.fetchProjects(search) },
        });
      }
    },
    searchProjects: debounce(function searchProjects(search) {
      this.fetchProjects(search);
    }, 500),
    selectProject(projectId) {
      this.currentProject = this.projects.find((p) => p.value === projectId);

      this.$emit('project-selected', this.currentProject.refsUrl);
    },
  },
};
</script>

<template>
  <div>
    <input
      id="merge_request_target_project_id"
      type="hidden"
      :value="currentProject.value"
      name="merge_request[target_project_id]"
      data-testid="target-project-input"
    />
    <gl-listbox
      v-model="selected"
      :items="projects"
      :toggle-text="currentProject.text"
      :header-text="__('Select target project')"
      :searching="isLoading"
      searchable
      class="gl-w-full dropdown-target-project"
      toggle-class="gl-align-items-flex-start! gl-justify-content-start! mr-compare-dropdown js-target-project"
      @shown="fetchProjects"
      @search="searchProjects"
      @select="selectProject"
    />
  </div>
</template>
