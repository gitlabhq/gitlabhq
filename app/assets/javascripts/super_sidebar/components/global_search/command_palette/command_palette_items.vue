<script>
import { debounce } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  USERS_ENDPOINT,
  COMMON_HANDLES,
  COMMAND_HANDLE,
  USER_HANDLE,
  GLOBAL_COMMANDS_GROUP_TITLE,
  USERS_GROUP_TITLE,
  PAGES_GROUP_TITLE,
} from './constants';
import { userMapper, commandMapper, linksReducer } from './utils';
import UserAutocompleteItem from './user_autocomplete_item.vue';
import CommandAutocompleteItem from './command_autocomplete_item.vue';

export default {
  name: 'CommandPaletteItems',
  components: {
    GlDisclosureDropdownGroup,
    GlLoadingIcon,
    UserAutocompleteItem,
    CommandAutocompleteItem,
  },
  inject: ['commandPaletteCommands', 'commandPaletteLinks'],
  props: {
    searchQuery: {
      type: String,
      required: true,
    },
    handle: {
      type: String,
      required: true,
      validator: (value) => {
        return COMMON_HANDLES.includes(value);
      },
    },
  },
  data: () => ({
    groups: [],
    error: null,
    loading: false,
  }),
  computed: {
    isCommandMode() {
      return this.handle === COMMAND_HANDLE;
    },
    isUserMode() {
      return this.handle === USER_HANDLE;
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
                name: name || GLOBAL_COMMANDS_GROUP_TITLE,
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
      return this.searchQuery?.length;
    },
  },
  watch: {
    searchQuery: {
      handler() {
        switch (this.handle) {
          case COMMAND_HANDLE:
            this.getCommandsAndPages();
            break;
          case USER_HANDLE:
            this.getUsers();
            break;
          default:
            break;
        }
      },
      immediate: true,
    },
  },
  methods: {
    filterBySearchQuery(items, key = 'keywords') {
      return fuzzaldrinPlus.filter(items, this.searchQuery, { key });
    },
    getCommandsAndPages() {
      if (!this.searchQuery) {
        this.groups = [...this.commands];
        return;
      }

      const matchedLinks = this.filterBySearchQuery(this.links);

      if (this.filteredCommands.length || matchedLinks.length) {
        this.groups = [];
      }

      if (this.filteredCommands.length) {
        this.groups = [...this.filteredCommands];
      }

      if (matchedLinks.length) {
        this.groups.push({
          name: PAGES_GROUP_TITLE,
          items: matchedLinks,
        });
      }
    },
    getUsers: debounce(function debouncedUserSearch() {
      if (this.searchQuery && this.searchQuery.length < 3) return null;

      this.loading = true;

      return axios
        .get(joinPaths(gon.relative_url_root || '', USERS_ENDPOINT), {
          params: {
            search: this.searchQuery,
          },
        })
        .then(({ data }) => {
          this.groups = [
            {
              name: USERS_GROUP_TITLE,
              items: data.map(userMapper),
            },
          ];
        })
        .catch((error) => {
          this.error = error;
        })
        .finally(() => {
          this.loading = false;
        });
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-m-0 gl-list-style-none">
    <gl-loading-icon v-if="loading" size="lg" class="gl-my-5" />

    <template v-else-if="hasResults">
      <gl-disclosure-dropdown-group
        v-for="(group, index) in groups"
        :key="index"
        :group="group"
        bordered
        class="{'gl-mt-0!': index===0}"
      >
        <template #list-item="{ item }">
          <user-autocomplete-item v-if="isUserMode" :user="item" :search-query="searchQuery" />
          <command-autocomplete-item
            v-if="isCommandMode"
            :command="item"
            :search-query="searchQuery"
          />
        </template>
      </gl-disclosure-dropdown-group>
    </template>

    <div v-else-if="hasSearchQuery && !hasResults" class="gl-text-gray-700 gl-pl-5 gl-py-3">
      {{ __('No results found') }}
    </div>
  </ul>
</template>
