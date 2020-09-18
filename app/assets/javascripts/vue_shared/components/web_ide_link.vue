<script>
import $ from 'jquery';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import ActionsButton from '~/vue_shared/components/actions_button.vue';

const KEY_WEB_IDE = 'webide';
const KEY_GITPOD = 'gitpod';

export default {
  components: {
    ActionsButton,
    LocalStorageSync,
  },
  props: {
    webIdeUrl: {
      type: String,
      required: false,
      default: '',
    },
    webIdeIsFork: {
      type: Boolean,
      required: false,
      default: false,
    },
    needsToFork: {
      type: Boolean,
      required: false,
      default: false,
    },
    showWebIdeButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    showGitpodButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    gitpodUrl: {
      type: String,
      required: false,
      default: '',
    },
    gitpodEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selection: KEY_WEB_IDE,
    };
  },
  computed: {
    actions() {
      return [this.webIdeAction, this.gitpodAction].filter(x => x);
    },
    webIdeAction() {
      if (!this.showWebIdeButton) {
        return null;
      }

      const handleOptions = this.needsToFork
        ? { href: '#modal-confirm-fork', handle: () => this.showModal('#modal-confirm-fork') }
        : { href: this.webIdeUrl };

      const text = this.webIdeIsFork ? __('Edit fork in Web IDE') : __('Web IDE');

      return {
        key: KEY_WEB_IDE,
        text,
        secondaryText: __('Quickly and easily edit multiple files in your project.'),
        tooltip: '',
        attrs: {
          'data-qa-selector': 'web_ide_button',
        },
        ...handleOptions,
      };
    },
    gitpodAction() {
      if (!this.showGitpodButton) {
        return null;
      }

      const handleOptions = this.gitpodEnabled
        ? { href: this.gitpodUrl }
        : { href: '#modal-enable-gitpod', handle: () => this.showModal('#modal-enable-gitpod') };

      const secondaryText = __('Launch a ready-to-code development environment for your project.');

      return {
        key: KEY_GITPOD,
        text: __('Gitpod'),
        secondaryText,
        tooltip: secondaryText,
        attrs: {
          'data-qa-selector': 'gitpod_button',
        },
        ...handleOptions,
      };
    },
  },
  methods: {
    select(key) {
      this.selection = key;
    },
    showModal(id) {
      $(id).modal('show');
    },
  },
};
</script>

<template>
  <div>
    <actions-button :actions="actions" :selected-key="selection" @select="select" />
    <local-storage-sync
      storage-key="gl-web-ide-button-selected"
      :value="selection"
      @input="select"
    />
  </div>
</template>
