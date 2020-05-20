<script>
import {
  GlNewDropdown,
  GlNewDropdownHeader,
  GlFormInputGroup,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getHTTPProtocol } from '~/lib/utils/url_utility';

export default {
  components: {
    GlNewDropdown,
    GlNewDropdownHeader,
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
  <gl-new-dropdown :text="$options.labels.defaultLabel" category="primary" variant="info">
    <div class="pb-2 mx-1">
      <template v-if="sshLink">
        <gl-new-dropdown-header>{{ $options.labels.ssh }}</gl-new-dropdown-header>

        <div class="mx-3">
          <gl-form-input-group :value="sshLink" readonly select-on-click>
            <template #append>
              <gl-button
                v-gl-tooltip.hover
                :title="$options.copyURLTooltip"
                :data-clipboard-text="sshLink"
                data-qa-selector="copy_ssh_url_button"
                icon="copy-to-clipboard"
                class="d-inline-flex"
              />
            </template>
          </gl-form-input-group>
        </div>
      </template>

      <template v-if="httpLink">
        <gl-new-dropdown-header>{{ httpLabel }}</gl-new-dropdown-header>

        <div class="mx-3">
          <gl-form-input-group :value="httpLink" readonly select-on-click>
            <template #append>
              <gl-button
                v-gl-tooltip.hover
                :title="$options.copyURLTooltip"
                :data-clipboard-text="httpLink"
                data-qa-selector="copy_http_url_button"
                icon="copy-to-clipboard"
                class="d-inline-flex"
              />
            </template>
          </gl-form-input-group>
        </div>
      </template>
    </div>
  </gl-new-dropdown>
</template>
