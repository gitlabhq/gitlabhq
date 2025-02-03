<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { debounce } from 'lodash';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { __, s__ } from '~/locale';
import { STORAGE_KEY } from '~/super_sidebar/constants';
import AccessorUtilities from '~/lib/utils/accessor';
import { getTopFrequentItems } from '~/super_sidebar/utils';
import namespaceProjectsForLinksWidgetQuery from '../../graphql/namespace_projects_for_links_widget.query.graphql';
import { SEARCH_DEBOUNCE, MAX_FREQUENT_PROJECTS } from '../../constants';

export default {
  components: {
    GlCollapsibleListbox,
    ProjectAvatar,
  },
  model: {
    prop: 'selectedProjectFullPath',
    event: 'selectProject',
  },
  props: {
    fullPath: {
      required: true,
      type: String,
    },
    currentProjectName: {
      required: false,
      type: String,
      default: '',
    },
    isGroup: {
      required: false,
      type: Boolean,
      default: false,
    },
    selectedProjectFullPath: {
      required: false,
      type: String,
      default: null,
    },
  },
  data() {
    return {
      projects: [],
      frequentProjects: [],
      searchKey: '',
      selectedProject: null,
    };
  },
  apollo: {
    projects: {
      query() {
        return namespaceProjectsForLinksWidgetQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          projectSearch: this.searchKey,
          includeArchived: false,
        };
      },
      update(data) {
        return data.namespace?.projects?.nodes;
      },
      result() {
        this.selectedProject = this.findSelectedProject(this.selectedProjectFullPath);
      },
    },
  },
  computed: {
    projectsLoading() {
      return this.$apollo.queries.projects.loading;
    },
    dropdownToggleText() {
      if (this.selectedProject) {
        /** When selectedProject is fetched from localStorage
         * name_with_namespace doesn't exist. Therefore we rely on
         * namespace directly.
         * */
        return this.selectedProject.nameWithNamespace || this.selectedProject.namespace;
      }
      return this.selectedProjectFullPath && this.currentProjectName
        ? this.currentProjectName
        : s__('WorkItem|Select a project');
    },
    listItems() {
      const items = [];
      let frequent = [];
      if (this.frequentProjects.length > 0) {
        frequent = this.frequentProjects.map((project) => {
          return {
            text: project.name,
            value: project.webUrl.startsWith('/')
              ? project.webUrl.substring(1, project.webUrl.length)
              : project.webUrl,
            namespace: project.namespace,
            avatarUrl: project.avatar_url,
          };
        });

        items.push({
          text: __('Recently used'),
          options: frequent,
        });
      }

      const frequentFullPaths = frequent.map((freq) => freq.value);

      if (this.projects.length > 0) {
        const allProjects = this.projects
          .filter((project) => {
            return !frequentFullPaths.includes(project.fullPath);
          })
          .map((project) => {
            return {
              text: project.name,
              value: project.fullPath,
              namespace: project.namespace?.name,
              avatarUrl: project.avatarUrl,
            };
          });

        items.push({
          text: __('Projects'),
          options: allProjects,
          textSrOnly: true,
        });
      }

      return items;
    },
  },
  created() {
    this.debouncedSearch = debounce(this.handleSearch, SEARCH_DEBOUNCE);
  },
  beforeDestroy() {
    this.debouncedSearch?.cancel();
  },
  methods: {
    handleSearch(keyword) {
      this.searchKey = keyword;
      this.setFrequentProjects(keyword);
    },
    handleSelect(projectFullPath) {
      this.selectedProject = this.findSelectedProject(projectFullPath);
      this.$emit('selectProject', projectFullPath);
    },
    findSelectedProject(projectFullPath) {
      const project = this.projects.find((proj) => proj.fullPath === projectFullPath);
      if (project) {
        return project;
      }
      return this.projects.find((proj) => {
        return `/${proj.fullPath}` === projectFullPath;
      });
    },
    async handleDropdownShow() {
      this.searchKey = '';
      this.setFrequentProjects();
      await this.$nextTick();
      this.$refs.searchInputField?.focusInput?.();
    },
    setFrequentProjects(searchTerm) {
      const { current_username: currentUsername } = gon;

      if (!currentUsername) {
        this.frequentProjects = [];
        return;
      }

      const storageKey = `${currentUsername}/${STORAGE_KEY.projects}`;

      if (!AccessorUtilities.canUseLocalStorage()) {
        this.frequentProjects = [];
        return;
      }

      const storedRawItems = localStorage.getItem(storageKey);

      let storedFrequentProjects = storedRawItems ? JSON.parse(storedRawItems) : [];

      /* Filter for the current group */
      storedFrequentProjects = storedFrequentProjects.filter((item) => {
        const groupPath = this.isGroup
          ? this.fullPath
          : this.fullPath.substring(0, this.fullPath.lastIndexOf('/'));

        return Boolean(item.webUrl?.slice(1)?.startsWith(groupPath));
      });

      if (searchTerm) {
        storedFrequentProjects = fuzzaldrinPlus.filter(storedFrequentProjects, searchTerm, {
          key: ['namespace'],
        });
      }

      this.frequentProjects = getTopFrequentItems(
        storedFrequentProjects,
        MAX_FREQUENT_PROJECTS,
      ).map((item) => {
        return { ...item, avatar_url: item.avatarUrl, web_url: item.webUrl };
      });
    },
    handleFrequentProjectSelection(selectedProject) {
      this.project = this.projects.find((proj) => {
        return `/${proj.fullPath}` === selectedProject.webUrl;
      });
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    searchable
    is-check-centered
    :items="listItems"
    :selected="selectedProjectFullPath"
    :toggle-text="dropdownToggleText"
    :searching="projectsLoading"
    fluid-width
    class="gl-relative"
    @search="debouncedSearch"
    @select="handleSelect"
    @shown="handleDropdownShow"
  >
    <template #list-item="{ item }">
      <div class="gl-flex gl-w-full gl-items-center">
        <project-avatar
          class="gl-mr-3"
          :project-id="item.id"
          :project-avatar-url="item.avatarUrl"
          :project-name="item.text"
        />
        <span>
          <span class="gl-mr-2 gl-block"> {{ item.text }} </span>
          <span class="gl-block gl-text-subtle"> {{ item.namespace }} </span>
        </span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
