<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CodeDropdownItem from '~/vue_shared/components/code_dropdown/code_dropdown_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    CodeDropdownItem,
  },
  props: {
    sshUrl: {
      type: String,
      required: false,
      default: '',
    },
    httpUrl: {
      type: String,
      required: false,
      default: '',
    },
    kerberosUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    httpLabel() {
      const protocol = getHTTPProtocol(this.httpUrl)?.toUpperCase();
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    :toggle-text="__('Code')"
    variant="confirm"
    placement="bottom-end"
    class="code-dropdown"
    fluid-width
    :auto-close="false"
    data-testid="code-dropdown"
  >
    <gl-disclosure-dropdown-group v-if="sshUrl">
      <code-dropdown-item
        :label="__('Clone with SSH')"
        label-class="!gl-text-sm !gl-pt-2"
        :link="sshUrl"
        name="ssh_project_clone"
        input-id="copy-ssh-url-input"
        test-id="copy-ssh-url-button"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="httpUrl">
      <code-dropdown-item
        :label="httpLabel"
        label-class="!gl-text-sm !gl-pt-2"
        :link="httpUrl"
        name="http_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="kerberosUrl">
      <code-dropdown-item
        :label="__('Clone with KRB5')"
        label-class="!gl-text-sm !gl-pt-2"
        :link="kerberosUrl"
        name="kerberos_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
<style>
/* Temporary override until we have
   * widths available in GlDisclosureDropdown
   * https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2501
   */
.code-dropdown .gl-new-dropdown-panel {
  width: 100%;
  max-width: 348px;
}
</style>
