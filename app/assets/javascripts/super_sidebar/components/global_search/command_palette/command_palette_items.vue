<script>
import { debounce } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import Tracking, { InternalEvents } from '~/tracking';
import { logError } from '~/lib/logger';
import { getFormattedItem } from '../utils';

import { EVENT_CLICK_PROJECT_SETTING_IN_COMMAND_PALETTE } from '../tracking_constants';
import {
  COMMON_HANDLES,
  COMMAND_HANDLE,
  USER_HANDLE,
  PROJECT_HANDLE,
  ISSUE_HANDLE,
  PATH_HANDLE,
  PAGES_GROUP_TITLE,
  SETTINGS_GROUP_TITLE,
  PATH_GROUP_TITLE,
  GROUP_TITLES,
  MAX_ROWS,
  TRACKING_ACTIVATE_COMMAND_PALETTE,
  TRACKING_HANDLE_LABEL_MAP,
} from './constants';
import SearchItem from './search_item.vue';
import { commandMapper, linksReducer, autocompleteQuery, fileMapper } from './utils';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'CommandPaletteItems',
  components: {
    GlDisclosureDropdownGroup,
    GlLoadingIcon,
    SearchItem,
  },
  mixins: [Tracking.mixin(), trackingMixin],
  inject: [
    'commandPaletteCommands',
    'commandPaletteLinks',
    'autocompletePath',
    'settingsPath',
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
        /* TODO: Search for recent issues initiated by #(ISSUE_HANDLE) from the command palette scope
         was removed as using the # in command palette conflicted
         with the existing global search functionality to search for issue by its id.
         The code that performs the Recent issues search was not removed from the code base
         as it would be nice to bring it back when we decide how to combine both search by id and text.
         In scope of https://gitlab.com/gitlab-org/gitlab/-/issues/417434
         we either bring back the search by #issue_text or remove the related code completely */
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
    settings: [],
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
    handle: {
      handler(value, oldValue) {
        // Do not run search immediately on component creation
        if (oldValue !== undefined) this.debouncedSearch();

        // Track immediately on component creation
        const label = TRACKING_HANDLE_LABEL_MAP[value] ?? 'unknown';
        this.track(TRACKING_ACTIVATE_COMMAND_PALETTE, { label });

        // Fetch settings results only for ">"
        if (value === COMMAND_HANDLE) this.fetchSettings();
      },
      immediate: true,
    },
  },
  updated() {
    this.$emit('updated');
  },
  methods: {
    fetchSettings() {
      let settingsUrl = null;
      const projectId = this.searchContext.project?.id;
      const groupId = this.searchContext.group?.id;

      if (projectId) {
        settingsUrl = `${this.settingsPath}?project_id=${projectId}`;
      } else if (groupId) {
        settingsUrl = `${this.settingsPath}?group_id=${groupId}`;
      } else {
        this.settings = [];
        return;
      }

      axios
        .get(settingsUrl)
        .then((response) => {
          this.settings = response.data;
        })
        .catch((e) => {
          logError(e);
          this.settings = [];
        });
    },
    filterBySearchQuery(items, key = 'keywords') {
      return fuzzaldrinPlus.filter(items, this.searchQuery, { key });
    },
    async getProjectFiles() {
      if (this.projectFilesPath && !this.projectFiles.length) {
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

      const matchedSettings = this.filterBySearchQuery(this.settings, 'text');

      if (matchedSettings.length) {
        this.groups.push({
          name: SETTINGS_GROUP_TITLE,
          items: matchedSettings,
        });
      }
    },
    async getScopedItems() {
      if (this.searchQuery?.length < 3) return;

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
    trackingCommands({ text: command }) {
      if (!this.isCommandMode || !this.searchContext.project?.id) {
        return;
      }
      const isSettings = this.settings.some((setting) => setting.text === command);
      if (!isSettings) {
        return;
      }

      this.trackEvent(EVENT_CLICK_PROJECT_SETTING_IN_COMMAND_PALETTE, {
        label: command,
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" size="lg" class="gl-my-5" />

    <ul v-else-if="hasResults" class="gl-m-0 gl-list-none gl-p-0">
      <gl-disclosure-dropdown-group
        v-for="(group, index) in groups"
        :key="index"
        :group="group"
        bordered
        :class="{ '!gl-mt-0': index === 0 }"
        @action="trackingCommands"
      >
        <template #list-item="{ item }">
          <search-item :item="item" :search-query="searchQuery" />
        </template>
      </gl-disclosure-dropdown-group>
    </ul>

    <div v-else-if="hasSearchQuery && !hasResults" class="gl-py-3 gl-pl-5 gl-text-default">
      {{ __('No results found') }}
    </div>
  </div>
</template>
