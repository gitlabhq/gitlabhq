<script>
import {
  GlIcon,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownForm,
  GlDropdownItem,
  GlSearchBoxByType,
  GlButton,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';

import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownForm,
    GlDropdownItem,
    GlSearchBoxByType,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    projectsFetchPath: {
      type: String,
      required: true,
    },
    dropdownButtonTitle: {
      type: String,
      required: true,
    },
    dropdownHeaderTitle: {
      type: String,
      required: true,
    },
    moveInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      projectsListLoading: false,
      projectsListLoadFailed: false,
      searchKey: '',
      projects: [],
      selectedProject: null,
      projectItemClick: false,
    };
  },
  computed: {
    hasNoSearchResults() {
      return Boolean(
        !this.projectsListLoading &&
          !this.projectsListLoadFailed &&
          this.searchKey &&
          !this.projects.length,
      );
    },
    failedToLoadResults() {
      return !this.projectsListLoading && this.projectsListLoadFailed;
    },
  },
  watch: {
    searchKey(value = '') {
      this.fetchProjects(value);
    },
  },
  methods: {
    fetchProjects(search = '') {
      this.projectsListLoading = true;
      this.projectsListLoadFailed = false;
      return axios
        .get(this.projectsFetchPath, {
          params: {
            search,
          },
        })
        .then(({ data }) => {
          this.projects = data;
          this.$refs.searchInput.focusInput();
        })
        .catch(() => {
          this.projectsListLoadFailed = true;
        })
        .finally(() => {
          this.projectsListLoading = false;
        });
    },
    isSelectedProject(project) {
      if (this.selectedProject) {
        return this.selectedProject.id === project.id;
      }
      return false;
    },
    /**
     * This handler is to prevent dropdown
     * from closing when an item is selected
     * and emit an event only when dropdown closes.
     */
    handleDropdownHide(e) {
      if (this.projectItemClick) {
        e.preventDefault();
        this.projectItemClick = false;
      } else {
        this.$emit('dropdown-close');
      }
    },
    handleDropdownCloseClick() {
      this.$refs.dropdown.hide();
    },
    handleProjectSelect(project) {
      this.selectedProject = project.id === this.selectedProject?.id ? null : project;
      this.projectItemClick = true;
    },
    handleMoveClick() {
      this.$refs.dropdown.hide();
      this.$emit('move-issuable', this.selectedProject);
    },
  },
};
</script>

<template>
  <div class="block js-issuable-move-block issuable-move-dropdown sidebar-move-issue-dropdown">
    <div
      v-gl-tooltip.left.viewport
      data-testid="move-collapsed"
      :title="dropdownButtonTitle"
      class="sidebar-collapsed-icon"
      @click="$emit('toggle-collapse')"
    >
      <gl-icon name="arrow-right" />
    </div>
    <gl-dropdown
      ref="dropdown"
      :block="true"
      :disabled="moveInProgress"
      class="hide-collapsed"
      toggle-class="js-sidebar-dropdown-toggle"
      @shown="fetchProjects"
      @hide="handleDropdownHide"
    >
      <template #button-content
        ><gl-loading-icon v-if="moveInProgress" size="sm" class="gl-mr-3" />{{
          dropdownButtonTitle
        }}</template
      >
      <gl-dropdown-form class="gl-pt-0">
        <div
          data-testid="header"
          class="gl-display-flex gl-pb-3 gl-border-1 gl-border-b-solid gl-border-gray-100"
        >
          <span class="gl-flex-grow-1 gl-text-center gl-font-weight-bold gl-py-1">{{
            dropdownHeaderTitle
          }}</span>
          <gl-button
            variant="link"
            icon="close"
            class="gl-mr-2 gl-w-auto! gl-p-2!"
            :aria-label="__('Close')"
            @click.prevent="handleDropdownCloseClick"
          />
        </div>
        <gl-search-box-by-type
          ref="searchInput"
          v-model.trim="searchKey"
          :placeholder="__('Search project')"
          :debounce="300"
        />
        <div data-testid="content" class="dropdown-content">
          <gl-loading-icon v-if="projectsListLoading" size="md" class="gl-p-5" />
          <ul v-else>
            <gl-dropdown-item
              v-for="project in projects"
              :key="project.id"
              :is-check-item="true"
              :is-checked="isSelectedProject(project)"
              @click.stop.prevent="handleProjectSelect(project)"
              >{{ project.name_with_namespace }}</gl-dropdown-item
            >
          </ul>
          <div v-if="hasNoSearchResults" class="gl-text-center gl-p-3">
            {{ __('No matching results') }}
          </div>
          <div v-if="failedToLoadResults" class="gl-text-center gl-p-3">
            {{ __('Failed to load projects') }}
          </div>
        </div>
        <div
          data-testid="footer"
          class="gl-pt-3 gl-px-3 gl-border-1 gl-border-t-solid gl-border-gray-100"
        >
          <gl-button
            category="primary"
            variant="success"
            :disabled="!Boolean(selectedProject)"
            class="gl-text-center! issuable-move-button"
            @click="handleMoveClick"
            >{{ __('Move') }}</gl-button
          >
        </div>
      </gl-dropdown-form>
    </gl-dropdown>
  </div>
</template>
