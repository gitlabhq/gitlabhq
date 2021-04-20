<script>
import {
  GlDropdown,
  GlDropdownSectionHeader,
  GlFormInputGroup,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownSectionHeader,
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
  <gl-dropdown right :text="$options.labels.defaultLabel" category="primary" variant="info">
    <div class="pb-2 mx-1">
      <template v-if="sshLink">
        <gl-dropdown-section-header>{{ $options.labels.ssh }}</gl-dropdown-section-header>

        <div class="mx-3">
          <gl-form-input-group :value="sshLink" readonly select-on-click>
            <template #append>
              <gl-button
                v-gl-tooltip.hover
                :title="$options.copyURLTooltip"
                :aria-label="$options.copyURLTooltip"
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
        <gl-dropdown-section-header>{{ httpLabel }}</gl-dropdown-section-header>

        <div class="mx-3">
          <gl-form-input-group :value="httpLink" readonly select-on-click>
            <template #append>
              <gl-button
                v-gl-tooltip.hover
                :title="$options.copyURLTooltip"
                :aria-label="$options.copyURLTooltip"
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
  </gl-dropdown>
</template>
