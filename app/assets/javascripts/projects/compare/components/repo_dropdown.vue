<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: ['targetProjectsPath'],
  props: {
    paramsName: {
      type: String,
      required: true,
    },
    selectedProject: {
      type: Object,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loadingProjects: false,
      allProjects: [],
    };
  },
  computed: {
    inputName() {
      return `${this.paramsName}_project_id`;
    },
  },
  mounted() {
    this.debouncedSearch = debounce(this.fetchForks, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

    this.fetchForks();
  },
  beforeDestroy() {
    if (this.debouncedSearch) {
      this.debouncedSearch.cancel();
    }
  },
  methods: {
    async fetchForks(search = '') {
      if (this.disabled) return;

      this.loadingProjects = true;

      try {
        const { data } = await axios.get(this.targetProjectsPath, {
          params: {
            search,
          },
        });

        this.allProjects = data.map((project) => ({
          ...project,
          value: project.id,
          text: project.full_name,
        }));
      } catch (error) {
        createAlert({
          message: s__('CompareRevisions|An error occurred while retrieving target projects.'),
          captureError: true,
          error,
        });
      } finally {
        this.loadingProjects = false;
      }
    },
    emitTargetProject(projectId) {
      const project = this.allProjects.find(({ value }) => value === projectId);

      if (project) {
        this.$emit('selectProject', { direction: this.paramsName, project });
      }
    },
    onSearch(searchTerm) {
      this.debouncedSearch(searchTerm);
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" :name="inputName" :value="selectedProject.value" />
    <gl-collapsible-listbox
      :selected="selectedProject.value"
      :toggle-text="selectedProject.text"
      :header-text="s__(`CompareRevisions|Select target project`)"
      :disabled="disabled"
      :items="allProjects"
      :searching="loadingProjects"
      block
      searchable
      @select="emitTargetProject"
      @search="onSearch"
    />
  </div>
</template>
