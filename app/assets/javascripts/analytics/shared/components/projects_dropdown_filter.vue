<script>
import { GlButton, GlIcon, GlAvatar, GlCollapsibleListbox, GlTruncate } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash';
import { filterBySearchTerm } from '~/analytics/shared/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { n__, s__, __ } from '~/locale';
import getProjects from '../graphql/projects.query.graphql';

const MIN_SEARCH_CHARS = 3;

const sortByProjectName = (projects = []) => projects.sort((a, b) => a.name.localeCompare(b.name));
const mapItemToListboxFormat = (item) => ({ ...item, value: item.id, text: item.name });

export default {
  name: 'ProjectsDropdownFilter',
  components: {
    GlButton,
    GlIcon,
    GlAvatar,
    GlCollapsibleListbox,
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
    toggleClasses: {
      type: String,
      required: false,
      default: '',
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
      }
      if (this.selectedProjects.length > 1) {
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
    selectedListBoxItems() {
      return this.multiSelect ? this.selectedProjectIds : this.selectedProjectIds[0];
    },
    hasSelectedProjects() {
      return Boolean(this.selectedProjects.length);
    },
    availableProjects() {
      return filterBySearchTerm(this.projects, this.searchTerm);
    },
    selectedItems() {
      return sortByProjectName(this.selectedProjects);
    },
    unselectedItems() {
      return this.availableProjects.filter(({ id }) => !this.selectedProjectIds.includes(id));
    },
    selectedGroupOptions() {
      return this.selectedItems.map(mapItemToListboxFormat);
    },
    unSelectedGroupOptions() {
      return this.unselectedItems.map(mapItemToListboxFormat);
    },
    listBoxItems() {
      if (this.selectedGroupOptions.length === 0) {
        return this.unSelectedGroupOptions;
      }

      return [
        {
          text: __('Selected'),
          options: this.selectedGroupOptions,
        },
        {
          text: __('Unselected'),
          options: this.unSelectedGroupOptions,
        },
      ];
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
    singleSelectedProject(selectedObj, isMarking) {
      return isMarking ? [selectedObj] : [];
    },
    getSelectedProjects(projects, selectedProjectIds) {
      return projects.filter(({ id }) => selectedProjectIds.includes(id));
    },
    setSelectedProjects(payload) {
      this.selectedProjects = this.multiSelect
        ? payload
        : this.singleSelectedProject(payload, !this.isProjectSelected(payload));
    },
    onClick(projectId) {
      const project = this.availableProjects.find(({ id }) => id === projectId);
      this.setSelectedProjects(project);
      this.handleUpdatedSelectedProjects();
    },
    onMultiSelectClick(projectIds) {
      const newlySelectedProjects = this.getSelectedProjects(this.availableProjects, projectIds);
      const selectedProjects = this.getSelectedProjects(this.selectedProjects, projectIds);

      this.setSelectedProjects(unionBy(newlySelectedProjects, selectedProjects, 'id'));
      this.isDirty = true;
    },
    onSelected(payload) {
      if (this.multiSelect) {
        this.onMultiSelectClick(payload);
      } else {
        this.onClick(payload);
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
    setSearchTerm(val) {
      if (val && val.length >= MIN_SEARCH_CHARS) {
        this.searchTerm = val;
        return;
      }

      this.searchTerm = '';
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>
<template>
  <gl-collapsible-listbox
    ref="projectsDropdown"
    :header-text="__('Projects')"
    :items="listBoxItems"
    :reset-button-label="__('Clear All')"
    :loading="loadingDefaultProjects"
    :multiple="multiSelect"
    :no-results-text="__('No matching results')"
    :selected="selectedListBoxItems"
    :searching="loading"
    searchable
    @hidden="onHide"
    @reset="onClearAll"
    @search="setSearchTerm"
    @select="onSelected"
  >
    <template #toggle>
      <gl-button
        button-text-classes="gl-w-full gl-justify-between gl-flex gl-shadow-none gl-mb-0"
        :class="['dropdown-projects', toggleClasses]"
      >
        <gl-avatar
          v-if="isOnlyOneProjectSelected"
          :src="selectedProjects[0].avatarUrl"
          :entity-id="getEntityId(selectedProjects[0])"
          :entity-name="selectedProjects[0].name"
          :size="16"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :alt="selectedProjects[0].name"
          class="gl-mr-2 gl-inline-flex gl-shrink-0 gl-align-middle"
        />
        <gl-truncate :text="selectedProjectsLabel" class="gl-min-w-0 gl-grow" />
        <gl-icon class="gl-ml-2 gl-shrink-0" name="chevron-down" />
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-flex">
        <gl-avatar
          class="gl-mr-2 gl-align-middle"
          :alt="item.name"
          :size="16"
          :entity-id="getEntityId(item)"
          :entity-name="item.name"
          :src="item.avatarUrl"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
        <div>
          <div data-testid="project-name">{{ item.name }}</div>
          <div class="gl-text-subtle" data-testid="project-full-path">
            {{ item.fullPath }}
          </div>
        </div>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
