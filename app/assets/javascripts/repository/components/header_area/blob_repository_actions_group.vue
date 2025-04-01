<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { keysFor, START_SEARCH_PROJECT_FILE } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK } from '~/tracking/constants';
import { showBlameButton } from '~/repository/utils/storage_info_utils';
import PermalinkDropdownItem from '~/repository/components/header_area/permalink_dropdown_item.vue';

export default {
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    PermalinkDropdownItem,
  },
  inject: ['blobInfo'],
  props: {
    permalinkPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    findFileShortcutKey() {
      return keysFor(START_SEARCH_PROJECT_FILE)[0];
    },
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
    blameItem() {
      return {
        text: __('Blame'),
        href: this.blobInfo.blamePath,
        extraAttrs: {
          'data-testid': 'blame',
        },
      };
    },
    showBlameButton() {
      return showBlameButton(this.blobInfo);
    },
  },
  methods: {
    handleFindFile() {
      InternalEvents.trackEvent(FIND_FILE_BUTTON_CLICK);
      Shortcuts.focusSearchFile();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-item
      :aria-keyshortcuts="findFileShortcutKey"
      data-testid="find"
      class="sm:gl-hidden"
      @action="handleFindFile"
    >
      <template #list-item>
        <span class="gl-flex gl-items-center gl-justify-between">
          <span>{{ __('Find file') }}</span>
          <kbd v-if="findFileShortcutKey && !shortcutsDisabled" class="flat">{{
            findFileShortcutKey
          }}</kbd>
        </span>
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item
      v-if="showBlameButton"
      :item="blameItem"
      class="js-blob-blame-link sm:gl-hidden"
      data-testid="blame-dropdown-item"
    />
    <permalink-dropdown-item :permalink-path="permalinkPath" />
  </gl-disclosure-dropdown-group>
</template>
