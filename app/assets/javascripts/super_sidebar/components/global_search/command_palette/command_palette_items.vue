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
  COMMANDS_GROUP_TITLE,
  USERS_GROUP_TITLE,
} from './constants';
import { userMapper, commandMapper } from './utils';
import UserAutocompleteItem from './user_autocomplete_item.vue';

export default {
  name: 'CommandPaletteItems',
  components: {
    GlDisclosureDropdownGroup,
    GlLoadingIcon,
    UserAutocompleteItem,
  },
  inject: ['commandPaletteData'],
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
    group: null,
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
      return this.commandPaletteData.map(commandMapper);
    },
    filteredCommands() {
      return this.searchQuery
        ? fuzzaldrinPlus.filter(this.commands, this.searchQuery, { key: 'keywords' })
        : this.commands;
    },
    commandsGroup() {
      return {
        name: COMMANDS_GROUP_TITLE,
        items: this.filteredCommands,
      };
    },
    hasResults() {
      return this.group?.items?.length;
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
            this.group = this.commandsGroup;
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
          this.group = {
            name: USERS_GROUP_TITLE,
            items: data.map(userMapper),
          };
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

    <gl-disclosure-dropdown-group v-else-if="hasResults" :group="group" bordered class="gl-mt-0!">
      <template v-if="isUserMode" #list-item="{ item }">
        <user-autocomplete-item :user="item" :search-query="searchQuery" />
      </template>
    </gl-disclosure-dropdown-group>
    <div v-else-if="hasSearchQuery && !hasResults" class="gl-text-gray-700 gl-pl-5 gl-py-3">
      {{ __('No results found') }}
    </div>
  </ul>
</template>
