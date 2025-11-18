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
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';

export default {
  i18n: {
    steps: {
      step1: __('Clone repository'),
    },
    cloneWithSsh: __('Clone with SSH'),
  },
  components: {
    GlButton,
    GlIcon,
    GlDisclosureDropdownItem,
    GlFormGroup,
    GlFormInputGroup,
    GlModal,
    SimpleCopyButton,
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
        <gl-icon name="branch" class="gl-mr-2" variant="subtle" />
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
              <simple-copy-button
                data-testid="wiki-copy-ssh-url-button"
                :text="cloneSshUrlDisplay"
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
              <simple-copy-button
                data-testid="wiki-copy-http-url-button"
                :text="cloneHttpUrlDisplay"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
      </div>
    </gl-modal>
  </div>
</template>
