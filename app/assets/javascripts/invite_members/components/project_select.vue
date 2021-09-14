<script>
import {
  GlAvatarLabeled,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { getProjects } from '~/rest_api';
import { SEARCH_DELAY, GROUP_FILTERS } from '../constants';

export default {
  name: 'ProjectSelect',
  components: {
    GlAvatarLabeled,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlSearchBoxByType,
  },
  model: {
    prop: 'selectedProject',
  },
  props: {
    groupsFilter: {
      type: String,
      required: false,
      default: GROUP_FILTERS.ALL,
      validator: (value) => Object.values(GROUP_FILTERS).includes(value),
    },
    parentGroupId: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      isFetching: false,
      projects: [],
      selectedProject: {},
      searchTerm: '',
      errorMessage: '',
    };
  },
  computed: {
    selectedProjectName() {
      return this.selectedProject.name || this.$options.i18n.dropdownText;
    },
    isFetchResultEmpty() {
      return this.projects.length === 0 && !this.isFetching;
    },
  },
  watch: {
    searchTerm() {
      this.retrieveProjects();
    },
  },
  mounted() {
    this.retrieveProjects();
  },
  methods: {
    retrieveProjects: debounce(function debouncedRetrieveProjects() {
      this.isFetching = true;
      this.errorMessage = '';
      return this.fetchProjects()
        .then((response) => {
          this.projects = response.data.map((project) => ({
            ...convertObjectPropsToCamelCase(project),
            name: project.name_with_namespace,
          }));
        })
        .catch(() => {
          this.errorMessage = this.$options.i18n.errorFetchingProjects;
        })
        .finally(() => {
          this.isFetching = false;
        });
    }, SEARCH_DELAY),
    fetchProjects() {
      return getProjects(this.searchTerm, this.$options.defaultFetchOptions);
    },
    selectProject(project) {
      this.selectedProject = project;

      this.$emit('input', this.selectedProject);
    },
  },
  i18n: {
    dropdownText: s__('ProjectSelect|Select a project'),
    searchPlaceholder: s__('ProjectSelect|Search projects'),
    emptySearchResult: s__('ProjectSelect|No matching results'),
    errorFetchingProjects: s__(
      'ProjectSelect|There was an error fetching the projects. Please try again.',
    ),
  },
  defaultFetchOptions: {
    exclude_internal: true,
    active: true,
  },
};
</script>
<template>
  <div>
    <gl-dropdown
      data-testid="project-select-dropdown"
      :text="selectedProjectName"
      toggle-class="gl-mb-2"
      block
      menu-class="gl-w-full!"
    >
      <gl-search-box-by-type
        v-model="searchTerm"
        :is-loading="isFetching"
        :placeholder="$options.i18n.searchPlaceholder"
        data-qa-selector="project_select_dropdown_search_field"
      />
      <gl-dropdown-item
        v-for="project in projects"
        :key="project.id"
        :name="project.name"
        @click="selectProject(project)"
      >
        <gl-avatar-labeled
          :label="project.name"
          :src="project.avatarUrl"
          :entity-id="project.id"
          :entity-name="project.name"
          :size="32"
        />
      </gl-dropdown-item>
      <gl-dropdown-text v-if="errorMessage" data-testid="error-message">
        <span class="gl-text-gray-500">{{ errorMessage }}</span>
      </gl-dropdown-text>
      <gl-dropdown-text v-else-if="isFetchResultEmpty" data-testid="empty-result-message">
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
    </gl-dropdown>
  </div>
</template>
