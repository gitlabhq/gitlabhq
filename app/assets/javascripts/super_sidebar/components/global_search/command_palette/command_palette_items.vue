<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { COMMON_HANDLES, COMMAND_HANDLE, COMMANDS_GROUP_TITLE } from './constants';

export default {
  name: 'CommandPaletteItems',
  components: {
    GlDisclosureDropdownGroup,
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
  computed: {
    isCommandMode() {
      return this.handle === COMMAND_HANDLE;
    },
    filteredCommands() {
      return this.searchQuery
        ? fuzzaldrinPlus.filter(this.commands, this.searchQuery, {
            key: 'keywords',
          })
        : this.commands;
    },
    commandsGroup() {
      return {
        name: COMMANDS_GROUP_TITLE,
        items: this.filteredCommands,
      };
    },
    commands() {
      return this.commandPaletteData.map(({ text, href, keywords = [] }) => ({
        text,
        href,
        keywords: keywords.join(''),
      }));
    },
    hasResults() {
      return this.commandsGroup.items?.length;
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-m-0 gl-list-style-none">
    <gl-disclosure-dropdown-group
      v-if="hasResults"
      :group="commandsGroup"
      bordered
      class="gl-mt-0!"
    />
    <div v-else class="gl-text-gray-700 gl-pl-5 gl-py-3">{{ __('No results found') }}</div>
  </ul>
</template>
