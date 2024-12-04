<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __, s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import namespaceGroupsForLinksWidgetQuery from '../../graphql/namespace_groups_for_links_widget.query.graphql';
import { SEARCH_DEBOUNCE } from '../../constants';

export default {
  components: {
    GlCollapsibleListbox,
    ProjectAvatar,
  },
  model: {
    prop: 'selectedGroupFullPath',
    event: 'selectGroup',
  },
  props: {
    fullPath: {
      required: true,
      type: String,
    },
    currentGroupName: {
      required: false,
      type: String,
      default: '',
    },
    isGroup: {
      required: false,
      type: Boolean,
      default: false,
    },
    selectedGroupFullPath: {
      required: false,
      type: String,
      default: null,
    },
  },
  data() {
    return {
      group: {},
      searchKey: '',
    };
  },
  apollo: {
    group: {
      query() {
        return namespaceGroupsForLinksWidgetQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          groupSearch: this.searchKey,
        };
      },
      error() {
        this.$emit('error', __('There was a problem fetching groups.'));
      },
    },
  },
  computed: {
    filteredGroups() {
      if (!this.group.id) {
        return [];
      }

      const filteredGroups = [];
      const searchMatchesGroup =
        this.searchKey && this.group.name.toLowerCase().includes(this.searchKey.toLowerCase());

      // group is not filtered by graphql query so we filter it here
      if (!this.searchKey || searchMatchesGroup) {
        const { id, name, avatarUrl, path, fullPath } = this.group;
        filteredGroups.push({ id, name, avatarUrl, path, fullPath });
      }

      if (this.group.descendantGroups) {
        filteredGroups.push(...this.group.descendantGroups.nodes);
      }

      return filteredGroups;
    },
    groupsLoading() {
      return this.$apollo.queries.group.loading;
    },
    dropdownToggleText() {
      if (this.selectedGroup) {
        return this.selectedGroup.name || this.selectedGroup.path;
      }
      return this.selectedGroupFullPath && this.currentGroupName
        ? this.currentGroupName
        : s__('WorkItem|Select a group');
    },
    listItems() {
      return this.filteredGroups.map((group) => {
        return {
          id: group.id,
          text: group.name,
          value: group.fullPath,
          namespace: group.path,
          avatarUrl: group.avatarUrl,
        };
      });
    },
    selectedGroup() {
      return this.filteredGroups.find((g) => g.fullPath === this.selectedGroupFullPath) || null;
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
    },
    handleSelect(groupFullPath) {
      this.$emit('selectGroup', groupFullPath);
    },
    async handleDropdownShow() {
      this.searchKey = '';
      await this.$nextTick();
      this.$refs.searchInputField?.focusInput?.();
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
    :selected="selectedGroupFullPath"
    :toggle-text="dropdownToggleText"
    :searching="groupsLoading"
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
          aria-hidden="true"
        />
        <span>
          <span class="gl-mr-2 gl-block"> {{ item.text }} </span>
          <span class="gl-block gl-text-subtle"> {{ item.namespace }} </span>
        </span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
