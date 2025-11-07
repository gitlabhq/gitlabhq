<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { debounce, unionBy } from 'lodash';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { __, s__ } from '~/locale';
import { STORAGE_KEY } from '~/super_sidebar/constants';
import { getTopFrequentItems } from '~/super_sidebar/utils';
import namespaceProjectsForLinksWidgetQuery from '../../graphql/namespace_projects_for_links_widget.query.graphql';
import namespaceGroupsForLinksWidgetQuery from '../../graphql/namespace_groups_for_links_widget.query.graphql';
import { SEARCH_DEBOUNCE, MAX_FREQUENT_ITEMS } from '../../constants';

export default {
  components: {
    GlCollapsibleListbox,
    ProjectAvatar,
  },
  model: {
    prop: 'selectedNamespacePath',
    event: 'selectNamespace',
  },
  props: {
    fullPath: {
      required: true,
      type: String,
    },
    isGroup: {
      required: true,
      type: Boolean,
    },
    selectedNamespacePath: {
      required: false,
      type: String,
      default: null,
    },
    limitToCurrentNamespace: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      projects: [],
      group: {},
      frequentItems: [],
      searchKey: '',
      namespaceCache: [],
    };
  },
  apollo: {
    projects: {
      query() {
        return namespaceProjectsForLinksWidgetQuery;
      },
      variables() {
        return {
          fullPath: this.limitToCurrentNamespace ? this.fullPath : this.rootPath,
          projectSearch: this.searchKey,
        };
      },
      update(data) {
        return data.namespace?.projects?.nodes;
      },
      error() {
        this.$emit('error', __('There was a problem fetching projects.'));
      },
    },
    group: {
      query() {
        return namespaceGroupsForLinksWidgetQuery;
      },
      variables() {
        return {
          fullPath: this.limitToCurrentNamespace ? this.fullPath : this.groupPath,
          groupSearch: this.searchKey,
        };
      },
      error() {
        this.$emit('error', __('There was a problem fetching groups.'));
      },
    },
  },
  computed: {
    selectedNamespace() {
      return this.namespaceCache.find(
        (namespace) => namespace.fullPath === this.selectedNamespacePath,
      );
    },
    rootPath() {
      return this.fullPath.split('/')[0];
    },
    isLoading() {
      return this.$apollo.queries.projects.loading || this.$apollo.queries.group.loading;
    },
    groupPath() {
      return this.isGroup
        ? this.rootPath
        : this.rootPath.substring(0, this.fullPath.lastIndexOf('/'));
    },
    dropdownToggleText() {
      if (this.selectedNamespace) {
        return (
          this.selectedNamespace.nameWithNamespace ||
          this.selectedNamespace.namespace ||
          this.selectedNamespace.name
        );
      }
      return this.fullPath
        ? this.defaultNamespace?.name ||
            this.defaultNamespace?.text ||
            this.defaultNamespace?.nameWithNamespace
        : s__('WorkItem|Select a namespace');
    },
    filteredGroups() {
      if (!this.group.id) {
        return [];
      }

      const filteredGroupsArr = [];
      const searchMatchesGroup =
        this.searchKey && this.group.name.toLowerCase().includes(this.searchKey.toLowerCase());

      // group is not filtered by graphql query so we filter it here
      if (!this.searchKey || searchMatchesGroup) {
        const { id, name, avatarUrl, path, fullPath } = this.group;
        filteredGroupsArr.push({ id, name, avatarUrl, path, fullPath });
      }

      if (this.group.descendantGroups) {
        filteredGroupsArr.push(...this.group.descendantGroups.nodes);
      }

      // Removing duplicate groups based on recently used groups
      const uniqueGroups = filteredGroupsArr.filter(
        (group) => !this.recentlyUsedFullPaths.includes(group.fullPath),
      );

      return uniqueGroups.map((group) => {
        return {
          id: group.id,
          text: group.name,
          value: group.fullPath,
          namespace: group.path,
          avatarUrl: group.avatarUrl,
        };
      });
    },
    filteredProjects() {
      if (!this.projects.length) {
        return [];
      }

      const allProjects = this.projects
        // Removing duplicate projects based on recently used projects
        .filter((project) => {
          return !this.recentlyUsedFullPaths.includes(project.fullPath);
        })
        .map((project) => {
          return {
            id: project.id,
            text: project.name,
            value: project.fullPath,
            namespace: project.nameWithNamespace || project.namespace?.name,
            avatarUrl: project.avatarUrl,
          };
        });

      return allProjects;
    },
    recentlyUsedItems() {
      const items = [];

      if (this.frequentItems.length > 0) {
        const recentItems = this.frequentItems.map((item) => {
          return {
            id: item.id,
            text: item.name,
            value: item.webUrl.startsWith('/')
              ? item.webUrl.substring(1, item.webUrl.length)
              : item.webUrl,
            namespace: item.namespace,
            avatarUrl: item.avatar_url,
          };
        });

        items.push({
          text: __('Recently used'),
          options: recentItems,
        });
      }
      return items;
    },
    recentlyUsedFullPaths() {
      return this.recentlyUsedItems.flatMap((section) => section.options.map((item) => item.value));
    },
    allGroupsAndProjects() {
      if (this.filteredGroups.length || this.filteredProjects.length) {
        return [
          {
            text: __('All groups and projects'),
            options: [...this.filteredGroups, ...this.filteredProjects],
          },
        ];
      }
      return [];
    },
    listItems() {
      return [...this.recentlyUsedItems, ...this.allGroupsAndProjects];
    },
    defaultNamespace() {
      return this.namespaceCache.find((namespace) => namespace.fullPath === this.fullPath);
    },
  },
  watch: {
    projects(projectsList) {
      this.namespaceCache = unionBy(this.namespaceCache, projectsList, 'id');
    },
    group(groupData) {
      const descendents = groupData.descendantGroups?.nodes || [];
      const groupList = [groupData, ...descendents];
      this.namespaceCache = unionBy(this.namespaceCache, groupList, 'id');
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
      this.setFrequentItems(keyword);
    },
    handleSelect(namespacePath) {
      this.$emit('selectNamespace', namespacePath);
    },
    async handleDropdownShow() {
      this.searchKey = '';
      this.setFrequentItems();
      await this.$nextTick();
      this.$refs.searchInputField?.focusInput?.();
    },
    setFrequentItems(searchTerm) {
      const { current_username: currentUsername } = gon;

      if (!currentUsername) {
        this.frequentItems = [];
        return;
      }

      try {
        const storedRawItems = localStorage.getItem(`${currentUsername}/${STORAGE_KEY.projects}`);
        const storedRawGroups = localStorage.getItem(`${currentUsername}/${STORAGE_KEY.groups}`);

        const storedFrequentProjects = storedRawItems ? JSON.parse(storedRawItems) : [];
        const storedFrequentGroups = storedRawGroups ? JSON.parse(storedRawGroups) : [];

        let storedFrequentItems = storedFrequentGroups.concat(storedFrequentProjects);

        /* Filter for the current group */
        storedFrequentItems = storedFrequentItems.filter((item) => {
          const groupPath = this.isGroup
            ? this.fullPath
            : this.fullPath.substring(0, this.fullPath.lastIndexOf('/'));

          return Boolean(item.webUrl?.slice(1)?.startsWith(groupPath));
        });

        if (searchTerm) {
          storedFrequentItems = fuzzaldrinPlus.filter(storedFrequentItems, searchTerm, {
            key: ['namespace'],
          });
        }

        this.frequentItems = getTopFrequentItems(storedFrequentItems, MAX_FREQUENT_ITEMS).map(
          (item) => {
            return { ...item, avatar_url: item.avatarUrl, web_url: item.webUrl };
          },
        );
      } catch (e) {
        this.frequentItems = [];
      }
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
    :selected="selectedNamespacePath"
    :toggle-text="dropdownToggleText"
    :searching="isLoading"
    fluid-width
    class="gl-relative"
    data-testid="work-item-namespace-selector"
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
