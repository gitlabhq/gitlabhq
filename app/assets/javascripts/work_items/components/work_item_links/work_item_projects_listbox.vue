<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
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
    prop: 'selectedProject',
    event: 'selectProject',
  },
  props: {
    fullPath: {
      required: true,
      type: String,
    },
    isGroup: {
      required: false,
      type: Boolean,
      default: false,
    },
    selectedProject: {
      required: false,
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      projects: [],
      frequentProjects: [],
      selectedProjectFullPath: null,
      searchKey: '',
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
        };
      },
      update(data) {
        return data.namespace?.projects?.nodes;
      },
      result() {
        if (this.selectedProject === null) {
          this.selectedProjectFullPath = this.fullPath;
        }
      },
      debounce: SEARCH_DEBOUNCE,
    },
  },
  computed: {
    dropdownToggleText() {
      if (this.selectedProject) {
        /** When selectedProject is fetched from localStorage
         * name_with_namespace doesn't exist. Therefore we rely on
         * namespace directly.
         * */
        return this.selectedProject.nameWithNamespace || this.selectedProject.namespace;
      }
      return s__('WorkItem|Select a project');
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
  watch: {
    selectedProjectFullPath(projectFullPath) {
      const project = this.findSelectedProject(projectFullPath);
      this.$emit('selectProject', project);
    },
  },
  methods: {
    handleSearch(keyword) {
      this.searchKey = keyword;
      this.setFrequentProjects(keyword);
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
    v-model="selectedProjectFullPath"
    block
    searchable
    is-check-centered
    :items="listItems"
    :toggle-text="dropdownToggleText"
    fluid-width
    class="gl-relative"
    @search="handleSearch"
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
          <span class="gl-block gl-mr-2"> {{ item.text }} </span>
          <span class="gl-block gl-text-secondary"> {{ item.namespace }} </span>
        </span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
