<script>
import Vue from 'vue';
import { GlDisclosureDropdownItem, GlToast } from '@gitlab/ui';
import { __ } from '~/locale';
import { keysFor, PROJECT_FILES_GO_TO_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { getBaseURL, relativePathToAbsolute } from '~/lib/utils/url_utility';
import { hashState } from '~/blob/state';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';

Vue.use(GlToast);

export default {
  components: {
    GlDisclosureDropdownItem,
  },
  props: {
    permalinkPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      mousetrap: null,
    };
  },
  computed: {
    permalinkShortcutKey() {
      return keysFor(PROJECT_FILES_GO_TO_PERMALINK)[0];
    },
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
    absolutePermalinkPath() {
      const baseAbsolutePath = relativePathToAbsolute(this.permalinkPath, getBaseURL());
      if (hashState.currentHash) {
        const page = getPageParamValue(hashState.currentHash);
        const searchString = getPageSearchString(baseAbsolutePath, page);
        if (Number.isNaN(Number(hashState.currentHash))) {
          return `${baseAbsolutePath}${searchString}${hashState.currentHash}`;
        }
        return `${baseAbsolutePath}${searchString}#L${hashState.currentHash}`;
      }
      return baseAbsolutePath;
    },
  },
  mounted() {
    this.mousetrap = new Mousetrap();
    this.mousetrap.bind(keysFor(PROJECT_FILES_GO_TO_PERMALINK), this.triggerCopyPermalink);
  },
  beforeDestroy() {
    this.mousetrap.unbind(keysFor(PROJECT_FILES_GO_TO_PERMALINK));
  },
  methods: {
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
</template>
