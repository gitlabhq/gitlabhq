<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import ConfirmForkModal from '~/vue_shared/components/web_ide/confirm_fork_modal.vue';
import { keysFor, GO_TO_PROJECT_WEBIDE } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { KEY_EDIT, KEY_WEB_IDE, KEY_GITPOD, KEY_PIPELINE_EDITOR } from './constants';

export const i18n = {
  webIdeText: s__('WebIDE|Quickly and easily edit multiple files in your project.'),
  webIdeTooltip: s__(
    'WebIDE|Quickly and easily edit multiple files in your project. Press . to open',
  ),
  toggleText: __('Edit'),
  gitpodText: __('Launch a ready-to-code development environment for your project.'),
};

const TRACKING_ACTION_NAME = 'click_consolidated_edit';

export default {
  name: 'CEWebIdeLink',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    ConfirmForkModal,
  },
  i18n,
  mixins: [Tracking.mixin()],
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
    needsToForkWithWebIde: {
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
    editUrl: {
      type: String,
      required: false,
      default: '',
    },
    buttonVariant: {
      type: String,
      required: false,
      default: null,
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
    cssClasses: {
      type: String,
      required: false,
      default: 'sm:gl-ml-3',
    },
  },
  data() {
    return {
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
    editButtonVariant() {
      if (this.buttonVariant) {
        return this.buttonVariant;
      }
      return this.isBlob ? 'confirm' : 'default';
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
        tracking: {
          action: TRACKING_ACTION_NAME,
          label: 'single_file',
        },
        ...handleOptions,
      };
    },
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
    webIdeActionShortcutKey() {
      return keysFor(GO_TO_PROJECT_WEBIDE)[0];
    },
    webIdeActionText() {
      if (this.webIdeText) {
        return this.webIdeText;
      }
      if (this.isBlob) {
        return __('Open in Web IDE');
      }
      if (this.isFork) {
        return __('Edit fork in Web IDE');
      }

      return __('Web IDE');
    },
    webIdeAction() {
      if (!this.showWebIdeButton) return null;

      const handleOptions = this.needsToForkWithWebIde
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
        shortcut: this.webIdeActionShortcutKey,
        tracking: {
          action: TRACKING_ACTION_NAME,
          label: 'web_ide',
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
      return this.showGitpodButton && this.gitpodEnabled && this.gitpodUrl;
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
        href: this.pipelineEditorUrl,
        tracking: {
          action: TRACKING_ACTION_NAME,
          label: 'pipeline_editor',
        },
      };
    },
    gitpodAction() {
      if (!this.computedShowGitpodButton) return null;

      const handleOptions = {
        handle: () => {
          visitUrl(this.gitpodUrl, true);
        },
      };

      return {
        key: KEY_GITPOD,
        text: this.gitpodActionText,
        secondaryText: this.$options.i18n.gitpodText,
        tracking: {
          action: TRACKING_ACTION_NAME,
          label: 'gitpod',
        },
        ...handleOptions,
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
    executeAction(action) {
      this.track(action.tracking.action, { label: action.tracking.label });
      action.handle?.();
    },
  },
};
</script>

<template>
  <div v-if="hasActions" :class="cssClasses">
    <gl-disclosure-dropdown
      :variant="editButtonVariant"
      :category="isBlob ? 'primary' : 'secondary'"
      :toggle-text="$options.i18n.toggleText"
      data-testid="action-dropdown"
      fluid-width
      block
      @shown="$emit('shown')"
      @hidden="$emit('hidden')"
    >
      <slot name="before-actions"></slot>
      <gl-disclosure-dropdown-group class="edit-dropdown-group-width">
        <gl-disclosure-dropdown-item
          v-for="action in actions"
          :key="action.key"
          :item="action"
          :data-testid="`${action.key}-menu-item`"
          @action="executeAction(action)"
        >
          <template #list-item>
            <div class="gl-flex gl-flex-col">
              <span class="gl-mb-2 gl-flex gl-items-center gl-justify-between">
                <span data-testid="action-primary-text" class="gl-font-bold">{{
                  action.text
                }}</span>
                <kbd v-if="action.shortcut && !shortcutsDisabled" class="flat">{{
                  action.shortcut
                }}</kbd>
              </span>
              <span data-testid="action-secondary-text" class="gl-text-sm gl-text-subtle">
                {{ action.secondaryText }}
              </span>
            </div>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
      <slot name="after-actions"></slot>
    </gl-disclosure-dropdown>
    <confirm-fork-modal
      v-if="mountForkModal"
      v-model="showForkModal"
      :modal-id="forkModalId"
      :fork-path="forkPath"
    />
  </div>
</template>
