<script>
import {
  GlButton,
  GlIcon,
  GlDisclosureDropdownItem,
  GlFormGroup,
  GlFormInputGroup,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';

export default {
  i18n: {
    steps: {
      step1: s__('WikiClone|Step 1: Clone repository'),
      step2: s__('WikiClone|Step 2: Install and start Gollum'),
      step2Directory: s__('WikiClone|Go to directory'),
      step2Install: s__('WikiClone|Install Gollum'),
      step2Start: s__('WikiClone|Start Gollum and edit locally'),
    },
    cloneWithSsh: __('Clone with SSH'),
    copyToClipboard: __('Copy to clipboard'),
    copyURLTooltip: __('Copy URL'),
  },
  components: {
    GlButton,
    GlIcon,
    GlDisclosureDropdownItem,
    GlFormGroup,
    GlFormInputGroup,
    GlModal,
    ClipboardButton,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    wikiPath: { default: null },
    cloneSshUrl: { default: null },
    cloneHttpUrl: { default: null },
  },
  props: {
    showAsDropdownItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    httpLabel() {
      const protocol = this.cloneHttpUrl ? getHTTPProtocol(this.cloneHttpUrl)?.toUpperCase() : '';
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
    cloneSshUrlDisplay() {
      return `git clone ${this.cloneSshUrl}`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    cloneHttpUrlDisplay() {
      return `git clone ${this.cloneHttpUrl}`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    directoryCommand() {
      return `cd ${this.wikiPath}`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    installCommand() {
      return 'gem install gollum'; // eslint-disable-line @gitlab/require-i18n-strings
    },
    gollumCommand() {
      return 'gollum';
    },
    listItem() {
      return {
        text: __('Clone repository'),
        extraAttrs: {
          'data-testid': 'page-clone-button',
        },
      };
    },
  },
  modal: {
    modalId: 'clone-wiki-modal',
  },
};
</script>

<template>
  <div v-if="cloneSshUrl || cloneHttpUrl">
    <gl-disclosure-dropdown-item
      v-if="showAsDropdownItem"
      v-gl-modal="$options.modal.modalId"
      :item="listItem"
    >
      <template #list-item>
        <gl-icon name="branch" class="gl-mr-2 gl-text-secondary" />
        {{ listItem.text }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-button
      v-else
      v-gl-modal="$options.modal.modalId"
      category="secondary"
      variant="confirm"
      data-testid="page-clone-button"
    >
      {{ listItem.text }}
    </gl-button>

    <gl-modal :modal-id="$options.modal.modalId" hide-footer>
      <template #modal-title>
        <h3 class="gl-heading-4 !gl-m-0" data-testid="wiki-clone-modal-title">
          {{ $options.i18n.steps.step1 }}
        </h3>
      </template>
      <div>
        <gl-form-group
          v-if="cloneSshUrl"
          :label="$options.i18n.cloneWithSsh"
          label-for="clone-ssh-url"
        >
          <gl-form-input-group
            id="clone-ssh-url"
            :value="cloneSshUrlDisplay"
            :label="$options.i18n.cloneWithSsh"
            input-class="!gl-font-monospace"
            readonly
            select-on-click
          >
            <template #append>
              <clipboard-button
                :text="cloneSshUrlDisplay"
                :title="$options.i18n.copyToClipboard"
                data-clipboard-text
                data-clipboard-target="#clone-ssh-url"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
        <gl-form-group v-if="cloneHttpUrl" :label="httpLabel" label-for="clone-http-url">
          <gl-form-input-group
            id="clone-http-url"
            :value="cloneHttpUrlDisplay"
            :label="httpLabel"
            input-class="!gl-font-monospace"
            readonly
            select-on-click
          >
            <template #append>
              <clipboard-button
                :text="cloneHttpUrlDisplay"
                :title="$options.i18n.copyToClipboard"
                data-clipboard-text
                data-clipboard-target="#clone-http-url"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
      </div>
      <div class="gl-mt-6">
        <h3 class="gl-heading-4">
          {{ $options.i18n.steps.step2 }}
        </h3>
        <gl-form-group :label="$options.i18n.steps.step2Directory" label-for="go-to-directory">
          <gl-form-input-group
            id="go-to-directory"
            :value="directoryCommand"
            :label="$options.i18n.steps.step2Directory"
            input-class="!gl-font-monospace"
            readonly
            select-on-click
          >
            <template #append>
              <clipboard-button
                :text="directoryCommand"
                :title="$options.i18n.copyToClipboard"
                data-clipboard-text
                data-clipboard-target="#go-to-directory"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
        <gl-form-group :label="$options.i18n.steps.step2Install" label-for="install-gollum">
          <gl-form-input-group
            id="install-gollum"
            :value="installCommand"
            :label="$options.i18n.steps.step2Install"
            input-class="!gl-font-monospace"
            readonly
            select-on-click
          >
            <template #append>
              <clipboard-button
                :text="installCommand"
                :title="$options.i18n.copyToClipboard"
                data-clipboard-text
                data-clipboard-target="#install-gollum"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
        <gl-form-group :label="$options.i18n.steps.step2Start" label-for="run-gollum">
          <gl-form-input-group
            id="run-gollum"
            :value="gollumCommand"
            :label="$options.i18n.steps.step2Start"
            input-class="!gl-font-monospace"
            readonly
            select-on-click
          >
            <template #append>
              <clipboard-button
                :text="gollumCommand"
                :title="$options.i18n.copyToClipboard"
                data-clipboard-text
                data-clipboard-target="#run-gollum"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
      </div>
    </gl-modal>
  </div>
</template>
