<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import { ListType } from '../constants';

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
  },
  components: {
    GlIntersectionObserver,
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
      selectedProject: {},
      searchTerm: '',
    };
  },
  computed: {
    ...mapState(['groupProjectsFlags']),
    ...mapGetters(['activeGroupProjects']),
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
      return this.activeGroupProjects.length === 0;
    },
    hasNextPage() {
      return this.groupProjectsFlags.pageInfo?.hasNextPage;
    },
  },
  watch: {
    searchTerm() {
      this.fetchGroupProjects({ search: this.searchTerm });
    },
  },
  mounted() {
    this.fetchGroupProjects({});

    this.initialLoading = false;
  },
  methods: {
    ...mapActions(['fetchGroupProjects', 'setSelectedProject']),
    selectProject(projectId) {
      this.selectedProject = this.activeGroupProjects.find((project) => project.id === projectId);
      this.setSelectedProject(this.selectedProject);
    },
    loadMoreProjects() {
      this.fetchGroupProjects({ search: this.searchTerm, fetchNext: true });
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
        v-for="project in activeGroupProjects"
        v-show="!groupProjectsFlags.isLoading"
        :key="project.id"
        :name="project.name"
        @click="selectProject(project.id)"
      >
        {{ project.nameWithNamespace }}
      </gl-dropdown-item>
      <gl-dropdown-text
        v-show="groupProjectsFlags.isLoading"
        data-testid="dropdown-text-loading-icon"
      >
        <gl-loading-icon class="gl-mx-auto" size="sm" />
      </gl-dropdown-text>
      <gl-dropdown-text
        v-if="isFetchResultEmpty && !groupProjectsFlags.isLoading"
        data-testid="empty-result-message"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
      <gl-intersection-observer v-if="hasNextPage" @appear="loadMoreProjects">
        <gl-loading-icon v-if="groupProjectsFlags.isLoadingMore" size="md" />
      </gl-intersection-observer>
    </gl-dropdown>
  </div>
</template>
