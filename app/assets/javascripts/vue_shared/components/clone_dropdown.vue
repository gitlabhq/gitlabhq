<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormGroup,
  GlFormInputGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlFormGroup,
    GlFormInputGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    sshLink: {
      type: String,
      required: false,
      default: '',
    },
    httpLink: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    httpLabel() {
      const protocol = this.httpLink ? getHTTPProtocol(this.httpLink)?.toUpperCase() : '';
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
  },
  labels: {
    defaultLabel: __('Clone'),
    ssh: __('Clone with SSH'),
  },
  copyURLTooltip: __('Copy URL'),
};
</script>
<template>
  <gl-disclosure-dropdown
    :toggle-text="$options.labels.defaultLabel"
    category="primary"
    variant="confirm"
    placement="right"
  >
    <gl-disclosure-dropdown-item v-if="sshLink">
      <gl-form-group :label="$options.labels.ssh" class="gl-px-3 gl-my-3">
        <gl-form-input-group :value="sshLink" readonly select-on-click>
          <template #append>
            <gl-button
              v-gl-tooltip.hover
              :title="$options.copyURLTooltip"
              :aria-label="$options.copyURLTooltip"
              :data-clipboard-text="sshLink"
              data-qa-selector="copy_ssh_url_button"
              icon="copy-to-clipboard"
              class="gl-display-inline-flex"
            />
          </template>
        </gl-form-input-group>
      </gl-form-group>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item v-if="httpLink">
      <gl-form-group :label="httpLabel" class="gl-px-3 gl-mb-3">
        <gl-form-input-group :value="httpLink" readonly select-on-click>
          <template #append>
            <gl-button
              v-gl-tooltip.hover
              :title="$options.copyURLTooltip"
              :aria-label="$options.copyURLTooltip"
              :data-clipboard-text="httpLink"
              data-qa-selector="copy_http_url_button"
              icon="copy-to-clipboard"
              class="gl-display-inline-flex"
            />
          </template>
        </gl-form-input-group>
      </gl-form-group>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
