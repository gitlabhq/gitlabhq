<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { getProjects } from '~/rest_api';
import { SEARCH_DELAY, GROUP_FILTERS, PROJECT_SELECT_LABEL_ID } from '../constants';

// We can have GlCollapsibleListbox dropdown panel with full
// width once we implement
// https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2133
// https://gitlab.com/gitlab-org/gitlab/-/issues/390411
export default {
  name: 'ProjectSelect',
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
  },
  model: {
    prop: 'selectedProjectId',
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
      selectedProjectId: '',
      searchTerm: '',
      errorMessage: '',
    };
  },
  computed: {
    selectedProjectName() {
      return this.selectedProject.nameWithNamespace || this.$options.i18n.dropdownText;
    },
    isFetchResultEmpty() {
      return this.projects.length === 0 && !this.isFetching;
    },
    selectedProject() {
      return this.projects.find((prj) => prj.id === this.selectedProjectId) || {};
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
            text: project.name_with_namespace,
            value: project.id,
          }));
        })
        .catch(() => {
          // To be displayed in GlCollapsibleListbox once we implement
          // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2132
          // https://gitlab.com/gitlab-org/gitlab/-/issues/389974
          this.errorMessage = this.$options.i18n.errorFetchingProjects;
        })
        .finally(() => {
          this.isFetching = false;
        });
    }, SEARCH_DELAY),
    fetchProjects() {
      return getProjects(this.searchTerm, this.$options.defaultFetchOptions);
    },
    selectProject() {
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
    projectSelectLabelId: PROJECT_SELECT_LABEL_ID,
  },
  defaultFetchOptions: {
    exclude_internal: true,
    active: true,
  },
};
</script>
<template>
  <gl-collapsible-listbox
    v-model="selectedProjectId"
    searchable
    :items="projects"
    :searching="isFetching"
    :toggle-text="selectedProjectName"
    :toggle-aria-labelled-by="$options.projectSelectLabelId"
    :search-placeholder="$options.i18n.searchPlaceholder"
    :no-results-text="$options.i18n.emptySearchResult"
    data-testid="project-select-dropdown"
    class="gl-collapsible-listbox-w-full"
    @search="searchTerm = $event"
    @select="selectProject"
  >
    <template #list-item="{ item }">
      <gl-avatar-labeled
        :label="item.text"
        :src="item.avatarUrl"
        :entity-id="item.id"
        :entity-name="item.name"
        :size="32"
      />
    </template>
  </gl-collapsible-listbox>
</template>
