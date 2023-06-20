<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import ActionsButton from '~/vue_shared/components/actions_button.vue';
import ConfirmForkModal from '~/vue_shared/components/web_ide/confirm_fork_modal.vue';
import { KEY_EDIT, KEY_WEB_IDE, KEY_GITPOD, KEY_PIPELINE_EDITOR } from './constants';

export const i18n = {
  modal: {
    title: __('Enable Gitpod?'),
    content: s__(
      'Gitpod|To use Gitpod you must first enable the feature in the integrations section of your %{linkStart}user preferences%{linkEnd}.',
    ),
    actionCancelText: __('Cancel'),
    actionPrimaryText: __('Enable Gitpod'),
  },
  webIdeText: s__('WebIDE|Quickly and easily edit multiple files in your project.'),
  webIdeTooltip: s__(
    'WebIDE|Quickly and easily edit multiple files in your project. Press . to open',
  ),
  toggleText: __('Edit'),
};

export default {
  components: {
    ActionsButton,
    GlModal,
    GlSprintf,
    GlLink,
    ConfirmForkModal,
  },
  i18n,
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
    showPipelineEditorButton: {
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
    pipelineEditorUrl: {
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
    webIdePromoPopoverImg: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showEnableGitpodModal: false,
      showForkModal: false,
    };
  },
  computed: {
    actions() {
      return [
        this.pipelineEditorAction,
        this.webIdeAction,
        this.editAction,
        this.gitpodAction,
      ].filter((action) => action);
    },
    hasActions() {
      return this.actions.length > 0;
    },
    editAction() {
      if (!this.showEditButton) return null;

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
        text: __('Edit single file'),
        secondaryText: __('Edit this file only.'),
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
        return __('Open in Web IDE');
      } else if (this.isFork) {
        return __('Edit fork in Web IDE');
      }

      return __('Web IDE');
    },
    webIdeAction() {
      if (!this.showWebIdeButton) return null;

      const handleOptions = this.needsToFork
        ? {
            handle: () => {
              if (this.disableForkModal) {
                this.$emit('edit', 'ide');
                return;
              }

              this.showModal('showForkModal');
            },
          }
        : {
            handle: () => {
              visitUrl(this.webIdeUrl, true);
            },
          };

      return {
        key: KEY_WEB_IDE,
        text: this.webIdeActionText,
        secondaryText: this.$options.i18n.webIdeText,
        attrs: {
          'data-qa-selector': 'web_ide_button',
          'data-track-action': 'click_consolidated_edit_ide',
          'data-track-label': 'web_ide',
        },
        ...handleOptions,
      };
    },
    gitpodActionText() {
      if (this.isBlob) {
        return __('Open in Gitpod');
      }
      return this.gitpodText || __('Gitpod');
    },
    computedShowGitpodButton() {
      return (
        this.showGitpodButton && this.userPreferencesGitpodPath && this.userProfileEnableGitpodPath
      );
    },
    pipelineEditorAction() {
      if (!this.showPipelineEditorButton) {
        return null;
      }

      const secondaryText = __('Edit, lint, and visualize your pipeline.');

      return {
        key: KEY_PIPELINE_EDITOR,
        text: __('Edit in pipeline editor'),
        secondaryText,
        attrs: {
          'data-qa-selector': 'pipeline_editor_button',
        },
        href: this.pipelineEditorUrl,
      };
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
    mountForkModal() {
      const { disableForkModal, showWebIdeButton, showEditButton } = this;
      if (disableForkModal) return false;

      return showWebIdeButton || showEditButton;
    },
  },
  methods: {
    showModal(dataKey) {
      this[dataKey] = true;
    },
  },
  webIdeButtonId: 'web-ide-link',
};
</script>

<template>
  <div class="gl-sm-ml-3">
    <actions-button
      v-if="hasActions"
      :id="$options.webIdeButtonId"
      :actions="actions"
      :toggle-text="$options.i18n.toggleText"
      :variant="isBlob ? 'confirm' : 'default'"
      :category="isBlob ? 'primary' : 'secondary'"
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
      v-if="mountForkModal"
      v-model="showForkModal"
      :modal-id="forkModalId"
      :fork-path="forkPath"
    />
  </div>
</template>
