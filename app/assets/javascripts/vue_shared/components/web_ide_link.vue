<script>
import $ from 'jquery';
import { __ } from '~/locale';
import ActionsButton from '~/vue_shared/components/actions_button.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

const KEY_EDIT = 'edit';
const KEY_WEB_IDE = 'webide';
const KEY_GITPOD = 'gitpod';

export default {
  components: {
    ActionsButton,
    LocalStorageSync,
  },
  props: {
    isFork: {
      type: Boolean,
      required: false,
      default: false,
    },
    needsToFork: {
      type: Boolean,
      required: false,
      default: false,
    },
    gitpodEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBlob: {
      type: Boolean,
      required: false,
      default: false,
    },
    showEditButton: {
      type: Boolean,
      required: false,
      default: true,
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
    editUrl: {
      type: String,
      required: false,
      default: '',
    },
    webIdeUrl: {
      type: String,
      required: false,
      default: '',
    },
    gitpodUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selection: KEY_WEB_IDE,
    };
  },
  computed: {
    actions() {
      return [this.webIdeAction, this.editAction, this.gitpodAction].filter((action) => action);
    },
    editAction() {
      if (!this.showEditButton) {
        return null;
      }

      const handleOptions = this.needsToFork
        ? {
            href: '#modal-confirm-fork-edit',
            handle: () => this.showModal('#modal-confirm-fork-edit'),
          }
        : { href: this.editUrl };

      return {
        key: KEY_EDIT,
        text: __('Edit'),
        secondaryText: __('Edit this file only.'),
        tooltip: '',
        attrs: {
          'data-qa-selector': 'edit_button',
          'data-track-action': 'click_consolidated_edit',
          'data-track-label': 'edit',
        },
        ...handleOptions,
      };
    },
    webIdeAction() {
      if (!this.showWebIdeButton) {
        return null;
      }

      const handleOptions = this.needsToFork
        ? {
            href: '#modal-confirm-fork-webide',
            handle: () => this.showModal('#modal-confirm-fork-webide'),
          }
        : { href: this.webIdeUrl };

      let text = __('Web IDE');

      if (this.isBlob) {
        text = __('Edit in Web IDE');
      } else if (this.isFork) {
        text = __('Edit fork in Web IDE');
      }

      return {
        key: KEY_WEB_IDE,
        text,
        secondaryText: __('Quickly and easily edit multiple files in your project.'),
        tooltip: '',
        attrs: {
          'data-qa-selector': 'web_ide_button',
          'data-track-action': 'click_consolidated_edit_ide',
          'data-track-label': 'web_ide',
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
  <div class="gl-sm-ml-3">
    <actions-button
      :actions="actions"
      :selected-key="selection"
      :variant="isBlob ? 'info' : 'default'"
      :category="isBlob ? 'primary' : 'secondary'"
      @select="select"
    />
    <local-storage-sync
      storage-key="gl-web-ide-button-selected"
      :value="selection"
      @input="select"
    />
  </div>
</template>
