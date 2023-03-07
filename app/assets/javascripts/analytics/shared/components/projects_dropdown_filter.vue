<script>
import {
  GlIcon,
  GlLoadingIcon,
  GlAvatar,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlSearchBoxByType,
  GlTruncate,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { filterBySearchTerm } from '~/analytics/shared/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { n__, s__, __ } from '~/locale';
import getProjects from '../graphql/projects.query.graphql';

const sortByProjectName = (projects = []) => projects.sort((a, b) => a.name.localeCompare(b.name));

export default {
  name: 'ProjectsDropdownFilter',
  components: {
    GlIcon,
    GlLoadingIcon,
    GlAvatar,
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlSearchBoxByType,
    GlTruncate,
  },
  props: {
    groupNamespace: {
      type: String,
      required: true,
    },
    multiSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: false,
      default: s__('CycleAnalytics|project dropdown filter'),
    },
    queryParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    defaultProjects: {
      type: Array,
      required: false,
      default: () => [],
    },
    loadingDefaultProjects: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: true,
      projects: [],
      selectedProjects: this.defaultProjects || [],
      searchTerm: '',
      isDirty: false,
    };
  },
  computed: {
    selectedProjectsLabel() {
      if (this.selectedProjects.length === 1) {
        return this.selectedProjects[0].name;
      } else if (this.selectedProjects.length > 1) {
        return n__(
          'CycleAnalytics|Project selected',
          'CycleAnalytics|%d projects selected',
          this.selectedProjects.length,
        );
      }

      return this.selectedProjectsPlaceholder;
    },
    selectedProjectsPlaceholder() {
      return this.multiSelect ? __('Select projects') : __('Select a project');
    },
    isOnlyOneProjectSelected() {
      return this.selectedProjects.length === 1;
    },
    selectedProjectIds() {
      return this.selectedProjects.map((p) => p.id);
    },
    hasSelectedProjects() {
      return Boolean(this.selectedProjects.length);
    },
    availableProjects() {
      return filterBySearchTerm(this.projects, this.searchTerm);
    },
    noResultsAvailable() {
      const { loading, availableProjects } = this;
      return !loading && !availableProjects.length;
    },
    selectedItems() {
      return sortByProjectName(this.selectedProjects);
    },
    unselectedItems() {
      return this.availableProjects.filter(({ id }) => !this.selectedProjectIds.includes(id));
    },
  },
  watch: {
    searchTerm() {
      this.search();
    },
    defaultProjects(projects) {
      this.selectedProjects = [...projects];
    },
  },
  mounted() {
    this.search();
  },
  methods: {
    handleUpdatedSelectedProjects() {
      this.$emit('selected', this.selectedProjects);
    },
    search: debounce(function debouncedSearch() {
      this.fetchData();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    getSelectedProjects(selectedProject, isSelected) {
      return isSelected
        ? this.selectedProjects.concat([selectedProject])
        : this.selectedProjects.filter((project) => project.id !== selectedProject.id);
    },
    singleSelectedProject(selectedObj, isMarking) {
      return isMarking ? [selectedObj] : [];
    },
    setSelectedProjects(project) {
      this.selectedProjects = this.multiSelect
        ? this.getSelectedProjects(project, !this.isProjectSelected(project))
        : this.singleSelectedProject(project, !this.isProjectSelected(project));
    },
    onClick(project) {
      this.setSelectedProjects(project);
      this.handleUpdatedSelectedProjects();
    },
    onMultiSelectClick(project) {
      this.setSelectedProjects(project);
      this.isDirty = true;
    },
    onSelected(project) {
      if (this.multiSelect) {
        this.onMultiSelectClick(project);
      } else {
        this.onClick(project);
      }
    },
    onHide() {
      if (this.multiSelect && this.isDirty) {
        this.handleUpdatedSelectedProjects();
      }
      this.searchTerm = '';
      this.isDirty = false;
    },
    onClearAll() {
      if (this.hasSelectedProjects) {
        this.isDirty = true;
      }
      this.selectedProjects = [];
    },
    fetchData() {
      this.loading = true;

      return this.$apollo
        .query({
          query: getProjects,
          variables: {
            groupFullPath: this.groupNamespace,
            search: this.searchTerm,
            ...this.queryParams,
          },
        })
        .then((response) => {
          const {
            data: {
              group: {
                projects: { nodes },
              },
            },
          } = response;

          this.loading = false;
          this.projects = nodes;
        });
    },
    isProjectSelected(project) {
      return this.selectedProjectIds.includes(project.id);
    },
    getEntityId(project) {
      return getIdFromGraphQLId(project.id);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>
<template>
  <gl-dropdown
    ref="projectsDropdown"
    class="dropdown dropdown-projects"
    toggle-class="gl-shadow-none gl-mb-0"
    :loading="loadingDefaultProjects"
    :show-clear-all="hasSelectedProjects"
    show-highlighted-items-title
    highlighted-items-title-class="gl-p-3"
    block
    @clear-all.stop="onClearAll"
    @hide="onHide"
  >
    <template #button-content>
      <gl-loading-icon v-if="loadingDefaultProjects" class="gl-mr-2 gl-flex-shrink-0" />
      <gl-avatar
        v-if="isOnlyOneProjectSelected"
        :src="selectedProjects[0].avatarUrl"
        :entity-id="getEntityId(selectedProjects[0])"
        :entity-name="selectedProjects[0].name"
        :size="16"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :alt="selectedProjects[0].name"
        class="gl-display-inline-flex gl-vertical-align-middle gl-mr-2 gl-flex-shrink-0"
      />
      <gl-truncate :text="selectedProjectsLabel" class="gl-min-w-0 gl-flex-grow-1" />
      <gl-icon class="gl-ml-2 gl-flex-shrink-0" name="chevron-down" />
    </template>
    <template #header>
      <gl-dropdown-section-header>{{ __('Projects') }}</gl-dropdown-section-header>
      <gl-search-box-by-type v-model.trim="searchTerm" :placeholder="__('Search')" />
    </template>
    <template #highlighted-items>
      <gl-dropdown-item
        v-for="project in selectedItems"
        :key="project.id"
        is-check-item
        :is-checked="isProjectSelected(project)"
        @click.native.capture.stop="onSelected(project)"
      >
        <div class="gl-display-flex">
          <gl-avatar
            class="gl-mr-2 gl-vertical-align-middle"
            :alt="project.name"
            :size="16"
            :entity-id="getEntityId(project)"
            :entity-name="project.name"
            :src="project.avatarUrl"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          />
          <div>
            <div data-testid="project-name">{{ project.name }}</div>
            <div class="gl-text-gray-500" data-testid="project-full-path">
              {{ project.fullPath }}
            </div>
          </div>
        </div>
      </gl-dropdown-item>
    </template>
    <gl-dropdown-item
      v-for="project in unselectedItems"
      :key="project.id"
      @click.native.capture.stop="onSelected(project)"
    >
      <div class="gl-display-flex">
        <gl-avatar
          class="gl-mr-2 vertical-align-middle"
          :alt="project.name"
          :size="16"
          :entity-id="getEntityId(project)"
          :entity-name="project.name"
          :src="project.avatarUrl"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
        <div>
          <div data-testid="project-name" data-qa-selector="project_name">{{ project.name }}</div>
          <div class="gl-text-gray-500" data-testid="project-full-path">
            {{ project.fullPath }}
          </div>
        </div>
      </div>
    </gl-dropdown-item>
    <gl-dropdown-item v-show="noResultsAvailable" class="gl-pointer-events-none text-secondary">{{
      __('No matching results')
    }}</gl-dropdown-item>
    <gl-dropdown-item v-if="loading">
      <gl-loading-icon size="lg" />
    </gl-dropdown-item>
  </gl-dropdown>
</template>
