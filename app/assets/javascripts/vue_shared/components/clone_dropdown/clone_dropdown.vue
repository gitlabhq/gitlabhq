<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CloneDropdownItem from './clone_dropdown_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    CloneDropdownItem,
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
};
</script>
<template>
  <gl-disclosure-dropdown
    :toggle-text="$options.labels.defaultLabel"
    category="primary"
    variant="confirm"
    placement="right"
  >
    <clone-dropdown-item
      v-if="sshLink"
      :label="$options.labels.ssh"
      :link="sshLink"
      qa-selector="copy_ssh_url_button"
    />
    <clone-dropdown-item
      v-if="httpLink"
      :label="httpLabel"
      :link="httpLink"
      qa-selector="copy_http_url_button"
    />
  </gl-disclosure-dropdown>
</template>
