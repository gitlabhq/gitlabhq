<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlLoadingIcon,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import Api from '../../api';
import { ListType } from '../constants';
import eventHub from '../eventhub';

export default {
  name: 'ProjectSelect',
  i18n: {
    headerTitle: s__(`BoardNewIssue|Projects`),
    dropdownText: s__(`BoardNewIssue|Select a project`),
    searchPlaceholder: s__(`BoardNewIssue|Search projects`),
    emptySearchResult: s__(`BoardNewIssue|No matching results`),
  },
  defaultFetchOptions: {
    with_issues_enabled: true,
    with_shared: false,
    include_subgroups: true,
    order_by: 'similarity',
    archived: false,
  },
  components: {
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlSearchBoxByType,
  },
  inject: ['groupId'],
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      initialLoading: true,
      isFetching: false,
      projects: [],
      selectedProject: {},
      searchTerm: '',
    };
  },
  computed: {
    selectedProjectName() {
      return this.selectedProject.name || this.$options.i18n.dropdownText;
    },
    fetchOptions() {
      const additionalAttrs = {};
      if (this.list.type && this.list.type !== ListType.backlog) {
        additionalAttrs.min_access_level = featureAccessLevel.EVERYONE;
      }

      return {
        ...this.$options.defaultFetchOptions,
        ...additionalAttrs,
      };
    },
    isFetchResultEmpty() {
      return this.projects.length === 0;
    },
  },
  watch: {
    searchTerm() {
      this.fetchProjects();
    },
  },
  async mounted() {
    await this.fetchProjects();

    this.initialLoading = false;
  },
  methods: {
    async fetchProjects() {
      this.isFetching = true;
      try {
        const projects = await Api.groupProjects(this.groupId, this.searchTerm, this.fetchOptions);

        this.projects = projects.map((project) => {
          return {
            id: project.id,
            name: project.name,
            namespacedName: project.name_with_namespace,
            path: project.path_with_namespace,
          };
        });
      } catch (err) {
        /* Handled in Api.groupProjects */
      } finally {
        this.isFetching = false;
      }
    },
    selectProject(projectId) {
      this.selectedProject = this.projects.find((project) => project.id === projectId);

      eventHub.$emit('setSelectedProject', this.selectedProject);
    },
  },
};
</script>

<template>
  <div>
    <label class="gl-font-weight-bold gl-mt-3" data-testid="header-label">{{
      $options.i18n.headerTitle
    }}</label>
    <gl-dropdown
      data-testid="project-select-dropdown"
      :text="selectedProjectName"
      :header-text="$options.i18n.headerTitle"
      block
      menu-class="gl-w-full!"
      :loading="initialLoading"
    >
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        debounce="250"
        :placeholder="$options.i18n.searchPlaceholder"
      />
      <gl-dropdown-item
        v-for="project in projects"
        v-show="!isFetching"
        :key="project.id"
        :name="project.name"
        @click="selectProject(project.id)"
      >
        {{ project.namespacedName }}
      </gl-dropdown-item>
      <gl-dropdown-text v-show="isFetching" data-testid="dropdown-text-loading-icon">
        <gl-loading-icon class="gl-mx-auto" size="sm" />
      </gl-dropdown-text>
      <gl-dropdown-text v-if="isFetchResultEmpty && !isFetching" data-testid="empty-result-message">
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
    </gl-dropdown>
  </div>
</template>
