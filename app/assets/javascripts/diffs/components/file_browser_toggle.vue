<script>
import { GlAnimatedSidebarIcon, GlButton, GlSprintf, GlTooltip } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { h } from 'vue';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { __ } from '~/locale';
import {
  keysFor,
  MR_TOGGLE_FILE_BROWSER,
  MR_TOGGLE_FILE_BROWSER_DEPRECATED,
} from '~/behaviors/shortcuts/keybindings';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { Mousetrap } from '~/lib/mousetrap';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';

export default {
  name: 'FileBrowserToggle',
  MR_TOGGLE_FILE_BROWSER,
  components: {
    GlButton,
    GlAnimatedSidebarIcon,
    GlTooltip,
    Shortcut,
  },
  computed: {
    ...mapState(useFileBrowser, ['fileBrowserVisible']),
    toggleFileBrowserShortcutKey() {
      return this.shortcutsEnabled ? keysFor(MR_TOGGLE_FILE_BROWSER)[0] : null;
    },
    shortcutsEnabled() {
      return !shouldDisableShortcuts();
    },
    toggleFileBrowserTitle() {
      return this.fileBrowserVisible ? __('Hide file browser') : __('Show file browser');
    },
  },
  created() {
    // we need to create the VNode in advance because `h` in Vue 2 only works here and in `mounted`
    this.legacyVNode = this.createLegacyShortcutVNode();
    this.initFileBrowserVisibility();
  },
  mounted() {
    if (this.shortcutsEnabled) {
      Mousetrap.bind(keysFor(MR_TOGGLE_FILE_BROWSER_DEPRECATED), this.toggleFileBrowserLegacy);
      Mousetrap.bind(keysFor(MR_TOGGLE_FILE_BROWSER), this.toggleFileBrowserVisibility);
    }
  },
  beforeDestroy() {
    if (this.shortcutsEnabled) {
      Mousetrap.unbind(keysFor(MR_TOGGLE_FILE_BROWSER_DEPRECATED));
      Mousetrap.unbind(keysFor(MR_TOGGLE_FILE_BROWSER));
    }
  },
  methods: {
    ...mapActions(useFileBrowser, ['toggleFileBrowserVisibility', 'initFileBrowserVisibility']),
    toggleFileBrowserLegacy() {
      if (!sessionStorage.getItem('notifiedOnLegacyFileBrowserToggle')) {
        this.$toast.show([this.legacyVNode]);
        sessionStorage.setItem('notifiedOnLegacyFileBrowserToggle', 'true');
      }
      this.toggleFileBrowserVisibility();
    },
    createLegacyShortcutVNode() {
      const message = __('The %{old} shortcut is deprecated. Use %{new} shortcut instead.');
      return h(GlSprintf, {
        props: { message },
        scopedSlots: {
          old: () =>
            h(Shortcut, { props: { shortcuts: MR_TOGGLE_FILE_BROWSER_DEPRECATED.defaultKeys } }),
          new: () => h(Shortcut, { props: { shortcuts: MR_TOGGLE_FILE_BROWSER.defaultKeys } }),
        },
      });
    },
  },
};
</script>

<template>
  <gl-button
    ref="toggle"
    variant="default"
    class="btn-icon gl-mr-3 max-lg:gl-hidden"
    data-testid="file-tree-button"
    :aria-label="toggleFileBrowserTitle"
    :aria-keyshortcuts="toggleFileBrowserShortcutKey"
    :selected="fileBrowserVisible"
    @click="toggleFileBrowserVisibility"
  >
    <gl-tooltip v-if="shortcutsEnabled" :target="() => $refs.toggle.$el">
      {{ toggleFileBrowserTitle }}
      <shortcut :shortcuts="$options.MR_TOGGLE_FILE_BROWSER.defaultKeys" />
    </gl-tooltip>
    <gl-animated-sidebar-icon :is-on="fileBrowserVisible" class="gl-button-icon" />
  </gl-button>
</template>
