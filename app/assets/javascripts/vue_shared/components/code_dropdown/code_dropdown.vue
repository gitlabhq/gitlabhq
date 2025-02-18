<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup, GlTooltipDirective } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CodeDropdownCloneItem from '~/repository/components/code_dropdown/code_dropdown_clone_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    CodeDropdownCloneItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    xcodeUrl: {
      type: String,
      required: false,
      default: '',
    },
    currentPath: {
      type: String,
      required: false,
      default: null,
    },
    directoryDownloadLinks: {
      type: Array,
      required: false,
      default: null,
    },
  },
  computed: {
    httpLabel() {
      const protocol = this.httpUrl ? getHTTPProtocol(this.httpUrl)?.toUpperCase() : '';
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
    sshUrlEncoded() {
      return encodeURIComponent(this.sshUrl);
    },
    httpUrlEncoded() {
      return encodeURIComponent(this.httpUrl);
    },
    ideGroup() {
      const items = [
        Boolean(this.sshUrl) && {
          text: __('Visual Studio Code (SSH)'),
          href: `${this.$options.vsCodeBaseUrl}${this.sshUrlEncoded}`,
        },
        Boolean(this.httpUrl) && {
          text: __('Visual Studio Code (HTTPS)'),
          href: `${this.$options.vsCodeBaseUrl}${this.httpUrlEncoded}`,
        },
        Boolean(this.sshUrl) && {
          text: __('IntelliJ IDEA (SSH)'),
          href: `${this.$options.jetBrainsBaseUrl}${this.sshUrlEncoded}`,
        },
        Boolean(this.httpUrl) && {
          text: __('IntelliJ IDEA (HTTPS)'),
          href: `${this.$options.jetBrainsBaseUrl}${this.httpUrlEncoded}`,
        },
        Boolean(this.xcodeUrl) && {
          text: __('Xcode'),
          href: this.xcodeUrl,
        },
      ].filter(Boolean);

      return {
        name: this.$options.i18n.openInIDE,
        items,
      };
    },
    sourceCodeGroup() {
      const items = this.directoryDownloadLinks.map((link) => ({
        text: link.text,
        href: link.path,
        extraAttrs: {
          rel: 'nofollow',
          download: '',
        },
      }));

      return {
        name: this.$options.i18n.downloadSourceCode,
        items,
      };
    },
    directoryDownloadLinksGroup() {
      const items = this.directoryDownloadLinks.map((link) => ({
        text: link.text,
        href: `${link.path}?path=${this.currentPath}`,
        extraAttrs: {
          rel: 'nofollow',
          download: '',
        },
      }));

      return {
        name: this.$options.i18n.downloadDirectory,
        items,
      };
    },
  },
  methods: {
    closeDropdown() {
      this.$refs.dropdown.close();
    },
  },
  vsCodeBaseUrl: 'vscode://vscode.git/clone?url=',
  jetBrainsBaseUrl:
    'jetbrains://idea/checkout/git?idea.required.plugins.id=Git4Idea&checkout.repo=',
  i18n: {
    defaultLabel: __('Code'),
    cloneWithSsh: __('Clone with SSH'),
    cloneWithKerberos: __('Clone with KRB5'),
    openInIDE: __('Open in your IDE'),
    downloadSourceCode: __('Download source code'),
    downloadDirectory: __('Download this directory'),
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    :toggle-text="$options.i18n.defaultLabel"
    category="primary"
    variant="confirm"
    placement="bottom-end"
    class="code-dropdown gl-text-left"
    fluid-width
    data-testid="code-dropdown"
    :auto-close="false"
  >
    <gl-disclosure-dropdown-group v-if="sshUrl">
      <code-dropdown-clone-item
        :label="$options.i18n.cloneWithSsh"
        :link="sshUrl"
        name="ssh_project_clone"
        input-id="copy-ssh-url-input"
        test-id="copy-ssh-url-button"
      />
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group v-if="httpUrl">
      <code-dropdown-clone-item
        :label="httpLabel"
        :link="httpUrl"
        name="http_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group v-if="kerberosUrl">
      <code-dropdown-clone-item
        :label="$options.i18n.cloneWithKerberos"
        :link="kerberosUrl"
        name="kerberos_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group :group="ideGroup" bordered @action="closeDropdown" />
    <gl-disclosure-dropdown-group
      v-if="directoryDownloadLinks"
      :group="sourceCodeGroup"
      bordered
      @action="closeDropdown"
    />
    <gl-disclosure-dropdown-group
      v-if="currentPath && directoryDownloadLinks"
      :group="directoryDownloadLinksGroup"
      bordered
      @action="closeDropdown"
    />
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
