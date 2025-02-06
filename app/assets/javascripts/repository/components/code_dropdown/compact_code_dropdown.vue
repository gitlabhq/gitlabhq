<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CodeDropdownCloneItem from './code_dropdown_clone_item.vue';
import CodeDropdownDownloadItems from './code_dropdown_download_items.vue';
import CodeDropdownIdeItem from './code_dropdown_ide_item.vue';
import { VSCODE_BASE_URL, JETBRAINS_BASE_URL } from './constants';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    CodeDropdownCloneItem,
    CodeDropdownDownloadItems,
    CodeDropdownIdeItem,
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
      default: () => [],
    },
  },
  computed: {
    httpLabel() {
      const protocol = getHTTPProtocol(this.httpUrl)?.toUpperCase();
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
    sshUrlEncoded() {
      return encodeURIComponent(this.sshUrl);
    },
    httpUrlEncoded() {
      return encodeURIComponent(this.httpUrl);
    },
    ideGroup() {
      const groups = [
        /* eslint-disable-next-line @gitlab/require-i18n-strings */
        this.createIdeGroup('Visual Studio Code', VSCODE_BASE_URL),
        this.createIdeGroup('IntelliJ IDEA', JETBRAINS_BASE_URL),
      ];

      if (this.xcodeUrl) {
        groups.push({
          /* eslint-disable-next-line @gitlab/require-i18n-strings */
          text: 'Xcode',
          href: this.xcodeUrl,
        });
      }

      return groups.filter((group) => group.items?.length || group.href);
    },
    sourceCodeGroup() {
      return this.directoryDownloadLinks.map((link) => ({
        text: link.text,
        href: link.path,
        extraAttrs: {
          rel: 'nofollow',
          download: '',
        },
      }));
    },
    directoryDownloadGroup() {
      return this.directoryDownloadLinks.map((link) => ({
        text: link.text,
        href: `${link.path}?path=${this.currentPath}`,
        extraAttrs: {
          rel: 'nofollow',
          download: '',
        },
      }));
    },
  },
  methods: {
    closeDropdown() {
      this.$refs.dropdown.close();
    },
    createIdeGroup(name, baseUrl) {
      return {
        text: name,
        items: [
          ...(this.sshUrl
            ? [
                {
                  text: 'SSH',
                  href: `${baseUrl}${this.sshUrlEncoded}`,
                },
              ]
            : []),
          ...(this.httpUrl
            ? [
                {
                  text: 'HTTPS',
                  href: `${baseUrl}${this.httpUrlEncoded}`,
                },
              ]
            : []),
        ],
      };
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    :toggle-text="__('Code')"
    variant="confirm"
    placement="bottom-end"
    class="code-dropdown"
    fluid-width
    :auto-close="false"
    data-testid="code-dropdown"
  >
    <gl-disclosure-dropdown-group v-if="sshUrl">
      <code-dropdown-clone-item
        :label="__('Clone with SSH')"
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
        :label="__('Clone with KRB5')"
        :link="kerberosUrl"
        name="kerberos_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="ideGroup.length" bordered>
      <template #group-label>{{ __('Open with') }}</template>
      <code-dropdown-ide-item
        v-for="(item, index) in ideGroup"
        :key="index"
        :ide-item="item"
        :label="__('Open with')"
        @close-dropdown="closeDropdown"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="directoryDownloadLinks.length" bordered>
      <template #group-label>{{ __('Download source code') }}</template>
      <code-dropdown-download-items :items="sourceCodeGroup" @close-dropdown="closeDropdown" />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="currentPath && directoryDownloadLinks.length" bordered>
      <template #group-label>{{ __('Download directory') }}</template>
      <code-dropdown-download-items
        :items="directoryDownloadGroup"
        @close-dropdown="closeDropdown"
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
