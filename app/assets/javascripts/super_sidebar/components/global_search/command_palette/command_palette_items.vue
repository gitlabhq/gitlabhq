<script>
import { debounce } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { getFormattedItem } from '../utils';

import {
  COMMON_HANDLES,
  COMMAND_HANDLE,
  USER_HANDLE,
  PROJECT_HANDLE,
  ISSUE_HANDLE,
  PATH_HANDLE,
  PAGES_GROUP_TITLE,
  PATH_GROUP_TITLE,
  GROUP_TITLES,
  MAX_ROWS,
} from './constants';
import SearchItem from './search_item.vue';
import { commandMapper, linksReducer, autocompleteQuery, fileMapper } from './utils';

export default {
  name: 'CommandPaletteItems',
  components: {
    GlDisclosureDropdownGroup,
    GlLoadingIcon,
    SearchItem,
  },
  inject: [
    'commandPaletteCommands',
    'commandPaletteLinks',
    'autocompletePath',
    'searchContext',
    'projectFilesPath',
    'projectBlobPath',
  ],
  props: {
    searchQuery: {
      type: String,
      required: true,
    },
    handle: {
      type: String,
      required: true,
      validator: (value) => {
        return [...COMMON_HANDLES, PATH_HANDLE].includes(value);
      },
    },
  },
  data: () => ({
    groups: [],
    loading: false,
    projectFiles: [],
    debouncedSearch: debounce(function debouncedSearch() {
      switch (this.handle) {
        case COMMAND_HANDLE:
          this.getCommandsAndPages();
          break;
        case USER_HANDLE:
        case PROJECT_HANDLE:
        case ISSUE_HANDLE:
          this.getScopedItems();
          break;
        case PATH_HANDLE:
          this.getProjectFiles();
          break;
        default:
          break;
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  }),
  computed: {
    isCommandMode() {
      return this.handle === COMMAND_HANDLE;
    },
    isPathMode() {
      return this.handle === PATH_HANDLE;
    },
    commands() {
      return this.commandPaletteCommands.map(commandMapper);
    },
    links() {
      return this.commandPaletteLinks.reduce(linksReducer, []);
    },
    filteredCommands() {
      return this.searchQuery
        ? this.commands
            .map(({ name, items }) => {
              return {
                name,
                items: this.filterBySearchQuery(items, 'text'),
              };
            })
            .filter(({ items }) => items.length)
        : this.commands;
    },
    hasResults() {
      return this.groups?.length && this.groups.some((group) => group.items?.length);
    },
    hasSearchQuery() {
      if (this.isCommandMode || this.isPathMode) {
        return this.searchQuery?.length > 0;
      }
      return this.searchQuery?.length > 2;
    },
    searchTerm() {
      if (this.handle === ISSUE_HANDLE) {
        return `${ISSUE_HANDLE}${this.searchQuery}`;
      }
      return this.searchQuery;
    },
    filteredProjectFiles() {
      if (!this.searchQuery) {
        return this.projectFiles.slice(0, MAX_ROWS);
      }
      return this.filterBySearchQuery(this.projectFiles, 'text').slice(0, MAX_ROWS);
    },
  },
  watch: {
    searchQuery: {
      handler() {
        this.debouncedSearch();
      },
      immediate: true,
    },
  },
  updated() {
    this.$emit('updated');
  },
  methods: {
    filterBySearchQuery(items, key = 'keywords') {
      return fuzzaldrinPlus.filter(items, this.searchQuery, { key });
    },
    async getProjectFiles() {
      if (!this.projectFiles.length) {
        this.loading = true;

        try {
          const response = await axios.get(this.projectFilesPath);
          this.projectFiles = response?.data.map(fileMapper.bind(null, this.projectBlobPath));
        } catch (error) {
          Sentry.captureException(error);
        } finally {
          this.loading = false;
        }
      }

      this.groups = [
        {
          name: PATH_GROUP_TITLE,
          items: this.filteredProjectFiles,
        },
      ];
    },
    getCommandsAndPages() {
      if (!this.searchQuery) {
        this.groups = [...this.commands];
        return;
      }

      this.groups = [...this.filteredCommands];

      const matchedLinks = this.filterBySearchQuery(this.links);

      if (matchedLinks.length) {
        this.groups.push({
          name: PAGES_GROUP_TITLE,
          items: matchedLinks,
        });
      }
    },
    async getScopedItems() {
      if (this.searchQuery && this.searchQuery.length < 3) return;

      this.loading = true;

      try {
        const response = await axios.get(
          autocompleteQuery({
            path: this.autocompletePath,
            searchTerm: this.searchTerm,
            handle: this.handle,
            projectId: this.searchContext.project?.id,
          }),
        );

        this.groups = [
          {
            name: GROUP_TITLES[this.handle],
            items: response.data.map(getFormattedItem),
          },
        ];
      } catch (error) {
        Sentry.captureException(error);
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" size="lg" class="gl-my-5" />

    <ul v-else-if="hasResults" class="gl-p-0 gl-m-0 gl-list-style-none">
      <gl-disclosure-dropdown-group
        v-for="(group, index) in groups"
        :key="index"
        :group="group"
        bordered
        :class="{ 'gl-mt-0!': index === 0 }"
      >
        <template #list-item="{ item }">
          <search-item :item="item" :search-query="searchQuery" />
        </template>
      </gl-disclosure-dropdown-group>
    </ul>

    <div v-else-if="hasSearchQuery && !hasResults" class="gl-text-gray-700 gl-pl-5 gl-py-3">
      {{ __('No results found') }}
    </div>
  </div>
</template>
