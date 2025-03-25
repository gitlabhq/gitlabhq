<script>
import Vue from 'vue';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlToast } from '@gitlab/ui';
import { __ } from '~/locale';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import {
  keysFor,
  PROJECT_FILES_GO_TO_PERMALINK,
  START_SEARCH_PROJECT_FILE,
} from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { getBaseURL, relativePathToAbsolute } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK } from '~/tracking/constants';
import { lineState } from '~/blob/state';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';
import { showBlameButton } from '~/repository/utils/storage_info_utils';

Vue.use(GlToast);

export default {
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
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
    permalinkShortcutKey() {
      return keysFor(PROJECT_FILES_GO_TO_PERMALINK)[0];
    },
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
    absolutePermalinkPath() {
      const baseAbsolutePath = relativePathToAbsolute(this.permalinkPath, getBaseURL());
      if (lineState.currentLineNumber) {
        const page = getPageParamValue(lineState.currentLineNumber);
        const searchString = getPageSearchString(baseAbsolutePath, page);
        return `${baseAbsolutePath}${searchString}#L${lineState.currentLineNumber}`;
      }
      return baseAbsolutePath;
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
  mounted() {
    Mousetrap.bind(keysFor(PROJECT_FILES_GO_TO_PERMALINK), this.triggerCopyPermalink);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(PROJECT_FILES_GO_TO_PERMALINK));
  },
  methods: {
    handleFindFile() {
      InternalEvents.trackEvent(FIND_FILE_BUTTON_CLICK);
      Shortcuts.focusSearchFile();
    },
    triggerCopyPermalink() {
      const buttonElement = this.$refs.copyPermalinkButton.$el;
      buttonElement.click();
      this.onCopyPermalink();
    },
    onCopyPermalink() {
      this.$toast.show(__('Permalink copied to clipboard.'));
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
    <gl-disclosure-dropdown-item
      ref="copyPermalinkButton"
      :aria-keyshortcuts="permalinkShortcutKey"
      data-testid="permalink"
      :data-clipboard-text="absolutePermalinkPath"
      data-clipboard-handle-tooltip="false"
      @action="onCopyPermalink"
    >
      <template #list-item>
        <span class="gl-flex gl-items-center gl-justify-between">
          <span>{{ __('Copy permalink') }}</span>
          <kbd v-if="permalinkShortcutKey && !shortcutsDisabled" class="flat">{{
            permalinkShortcutKey
          }}</kbd>
        </span>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown-group>
</template>
