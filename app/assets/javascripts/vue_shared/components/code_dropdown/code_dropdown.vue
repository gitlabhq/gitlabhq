<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup, GlTooltipDirective } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CloneDropdownItem from '~/vue_shared/components/clone_dropdown/clone_dropdown_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    CloneDropdownItem,
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
    unfilteredDropdownItems() {
      return [
        {
          item: {
            text: __('Visual Studio Code (SSH)'),
            href: `${this.vsCodeBaseUrl}${this.sshUrlEncoded}`,
          },
          isIncluded: Boolean(this.sshUrl),
        },
        {
          item: {
            text: __('Visual Studio Code (HTTPS)'),
            href: `${this.vsCodeBaseUrl}${this.httpUrlEncoded}`,
          },
          isIncluded: Boolean(this.httpUrl),
        },
        {
          item: {
            text: __('IntelliJ IDEA (SSH)'),
            href: `${this.jetBrainsBaseUrl}${this.sshUrlEncoded}`,
          },
          isIncluded: Boolean(this.sshUrl),
        },
        {
          item: {
            text: __('IntelliJ IDEA (HTTPS)'),
            href: `${this.jetBrainsBaseUrl}${this.httpUrlEncoded}`,
          },
          isIncluded: Boolean(this.httpUrl),
        },
        {
          item: {
            text: __('Xcode'),
            href: this.xcodeUrl,
          },
          isIncluded: Boolean(this.xcodeUrl),
        },
      ];
    },
    ideGroup() {
      const items = [];

      this.unfilteredDropdownItems.forEach(({ item, isIncluded }) => {
        if (isIncluded) {
          items.push(item);
        }
      });

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
  vsCodeBaseUrl: 'vscode://vscode.git/clone?url=',
  jetBrainsBaseUrl:
    'jetbrains://idea/checkout/git?idea.required.plugins.id=Git4Idea&checkout.repo=',
  i18n: {
    defaultLabel: __('Code'),
    cloneWithSsh: __('Clone with SSH'),
    cloneWithKerberos: __('Clone with KRB5'),
    openInIDE: __('Open in your IDE'),
    downloadSourceCode: __('Download Source Code'),
    downloadDirectory: __('Download this directory'),
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    :toggle-text="$options.i18n.defaultLabel"
    category="primary"
    variant="confirm"
    placement="right"
    class="code-dropdown gl-text-left"
    fluid-width
    data-testid="code-dropdown"
  >
    <gl-disclosure-dropdown-group v-if="sshUrl">
      <clone-dropdown-item
        :label="$options.i18n.cloneWithSsh"
        label-class="gl-font-sm! gl-pt-2!"
        :link="sshUrl"
        name="ssh_project_clone"
        input-test-id="copy-ssh-url-input"
        test-id="copy-ssh-url-button"
      />
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group v-if="httpUrl">
      <clone-dropdown-item
        :label="httpLabel"
        label-class="gl-font-sm! gl-pt-2!"
        :link="httpUrl"
        name="http_project_clone"
        input-test-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group v-if="kerberosUrl">
      <clone-dropdown-item
        :label="$options.i18n.cloneWithKerberos"
        label-class="gl-font-sm! gl-pt-2!"
        :link="kerberosUrl"
        name="kerberos_project_clone"
        input-test-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group :group="ideGroup" bordered />
    <gl-disclosure-dropdown-group v-if="directoryDownloadLinks" :group="sourceCodeGroup" bordered />
    <gl-disclosure-dropdown-group
      v-if="currentPath && directoryDownloadLinks"
      :group="directoryDownloadLinksGroup"
      bordered
    />
  </gl-disclosure-dropdown>
</template>
<style>
/* Temporary override until we have
   * widths available in GlDisclosureDropdown
   */
.code-dropdown .gl-new-dropdown-panel {
  width: 100%;
  max-width: 348px;
}
</style>
