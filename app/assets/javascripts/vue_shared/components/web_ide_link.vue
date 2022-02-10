<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ActionsButton from '~/vue_shared/components/actions_button.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import ConfirmForkModal from '~/vue_shared/components/confirm_fork_modal.vue';

const KEY_EDIT = 'edit';
const KEY_WEB_IDE = 'webide';
const KEY_GITPOD = 'gitpod';

export default {
  components: {
    ActionsButton,
    LocalStorageSync,
    GlModal,
    GlSprintf,
    GlLink,
    ConfirmForkModal,
  },
  i18n: {
    modal: {
      title: __('Enable Gitpod?'),
      content: s__(
        'Gitpod|To use Gitpod you must first enable the feature in the integrations section of your %{linkStart}user preferences%{linkEnd}.',
      ),
      actionCancelText: __('Cancel'),
      actionPrimaryText: __('Enable Gitpod'),
    },
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
    userPreferencesGitpodPath: {
      type: String,
      required: false,
      default: '',
    },
    userProfileEnableGitpodPath: {
      type: String,
      required: false,
      default: '',
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
    webIdeText: {
      type: String,
      required: false,
      default: '',
    },
    gitpodUrl: {
      type: String,
      required: false,
      default: '',
    },
    gitpodText: {
      type: String,
      required: false,
      default: '',
    },
    disableForkModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    forkPath: {
      type: String,
      required: false,
      default: '',
    },
    forkModalId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selection: KEY_WEB_IDE,
      showEnableGitpodModal: false,
      showForkModal: false,
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
            handle: () => {
              if (this.disableForkModal) {
                this.$emit('edit', 'simple');
                return;
              }

              this.showModal('showForkModal');
            },
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
    webIdeActionText() {
      if (this.webIdeText) {
        return this.webIdeText;
      } else if (this.isBlob) {
        return __('Edit in Web IDE');
      } else if (this.isFork) {
        return __('Edit fork in Web IDE');
      }

      return __('Web IDE');
    },
    webIdeAction() {
      if (!this.showWebIdeButton) {
        return null;
      }

      const handleOptions = this.needsToFork
        ? {
            href: '#modal-confirm-fork-webide',
            handle: () => {
              if (this.disableForkModal) {
                this.$emit('edit', 'ide');
                return;
              }

              this.showModal('showForkModal');
            },
          }
        : { href: this.webIdeUrl };

      return {
        key: KEY_WEB_IDE,
        text: this.webIdeActionText,
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
    gitpodActionText() {
      return this.gitpodText || __('Gitpod');
    },
    computedShowGitpodButton() {
      return (
        this.showGitpodButton && this.userPreferencesGitpodPath && this.userProfileEnableGitpodPath
      );
    },
    gitpodAction() {
      if (!this.computedShowGitpodButton) {
        return null;
      }

      const handleOptions = this.gitpodEnabled
        ? { href: this.gitpodUrl }
        : {
            handle: () => {
              this.showModal('showEnableGitpodModal');
            },
          };

      const secondaryText = __('Launch a ready-to-code development environment for your project.');

      return {
        key: KEY_GITPOD,
        text: this.gitpodActionText,
        secondaryText,
        tooltip: secondaryText,
        attrs: {
          'data-qa-selector': 'gitpod_button',
        },
        ...handleOptions,
      };
    },
    enableGitpodModalProps() {
      return {
        'modal-id': 'enable-gitpod-modal',
        size: 'sm',
        title: this.$options.i18n.modal.title,
        'action-cancel': {
          text: this.$options.i18n.modal.actionCancelText,
        },
        'action-primary': {
          text: this.$options.i18n.modal.actionPrimaryText,
          attributes: {
            variant: 'confirm',
            category: 'primary',
            href: this.userProfileEnableGitpodPath,
            'data-method': 'put',
          },
        },
      };
    },
  },
  methods: {
    select(key) {
      this.selection = key;
    },
    showModal(dataKey) {
      this[dataKey] = true;
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
    <gl-modal
      v-if="computedShowGitpodButton && !gitpodEnabled"
      v-model="showEnableGitpodModal"
      v-bind="enableGitpodModalProps"
    >
      <gl-sprintf :message="$options.i18n.modal.content">
        <template #link="{ content }">
          <gl-link :href="userPreferencesGitpodPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-modal>
    <confirm-fork-modal
      v-if="showWebIdeButton || showEditButton"
      v-model="showForkModal"
      :modal-id="forkModalId"
      :fork-path="forkPath"
    />
  </div>
</template>
