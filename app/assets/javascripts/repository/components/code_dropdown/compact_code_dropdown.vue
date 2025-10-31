<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { getHTTPProtocol, mergeUrlParams } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { GO_TO_PROJECT_WEBIDE, keysFor } from '~/behaviors/shortcuts/keybindings';
import CodeDropdownCloneItem from './code_dropdown_clone_item.vue';
import CodeDropdownDownloadItems from './code_dropdown_download_items.vue';
import CodeDropdownIdeItem from './code_dropdown_ide_item.vue';
import { VSCODE_BASE_URL, JETBRAINS_BASE_URL } from './constants';

export default {
  name: 'CECompactCodeDropdown',
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
    webIdeUrl: {
      type: String,
      required: false,
      default: '',
    },
    gitpodUrl: {
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
    showWebIdeButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    isGitpodEnabledForInstance: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGitpodEnabledForUser: {
      type: Boolean,
      required: false,
      default: false,
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
    webIdeActionShortcutKey() {
      return keysFor(GO_TO_PROJECT_WEBIDE)[0];
    },
    webIdeAction() {
      return {
        text: __('Web IDE'),
        shortcut: this.webIdeActionShortcutKey,
        tracking: {
          action: 'click_consolidated_edit',
          label: 'web_ide',
        },
        testId: 'webide-menu-item',
        href: this.webIdeUrl,
        extraAttrs: {
          target: '_blank',
        },
      };
    },
    showGitpodButton() {
      return this.isGitpodEnabledForInstance && this.isGitpodEnabledForUser && this.gitpodUrl;
    },
    gitPodAction() {
      return {
        text: __('GitPod'),
        tracking: {
          action: 'click_consolidated_edit',
          label: 'gitpod',
        },
        href: this.gitpodUrl,
        extraAttrs: {
          target: '_blank',
        },
      };
    },
    ideGroup() {
      const actions = [];

      if (this.showWebIdeButton) actions.push(this.webIdeAction);
      if (this.showGitpodButton) actions.push(this.gitPodAction);

      if (this.httpUrl || this.sshUrl) {
        actions.push(this.createIdeGroup(__('Visual Studio Code'), VSCODE_BASE_URL));
        actions.push(this.createIdeGroup(__('IntelliJ IDEA'), JETBRAINS_BASE_URL));
      }

      if (this.xcodeUrl) {
        actions.push({
          text: __('Xcode'),
          href: this.xcodeUrl,
          extraAttrs: { isUnsafeLink: true },
        });
      }

      return actions;
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
      return this.directoryDownloadLinks.map((link) => {
        const hrefEncoded = mergeUrlParams({ path: this.currentPath }, link.path);
        const href = hrefEncoded.replace(/%2F/g, '/');
        return {
          text: link.text,
          href,
          extraAttrs: {
            rel: 'nofollow',
            download: '',
          },
        };
      });
    },
    groups() {
      let firstVisibleGroup = null;

      return [
        // Important: the order of this array must match the order of the
        // GlDisclosureDropdownGroups in the template.
        ['sshUrl', this.sshUrl],
        ['httpUrl', this.httpUrl],
        ['kerberosUrl', this.kerberosUrl],
        ['ideGroup', this.ideGroup.length > 0],
        ['downloadSourceCode', this.directoryDownloadLinks.length > 0],
        ['downloadDirectory', this.currentPath && this.directoryDownloadLinks.length > 0],
      ].reduce((acc, [groupName, shouldShowGroup]) => {
        let bordered = Boolean(shouldShowGroup);

        if (!firstVisibleGroup && shouldShowGroup) {
          firstVisibleGroup = groupName;
          bordered = false;
        }

        acc[groupName] = { show: shouldShowGroup, bordered };
        return acc;
      }, {});
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
                  text: __('SSH'),
                  href: `${baseUrl}${this.sshUrlEncoded}`,
                  extraAttrs: {
                    isUnsafeLink: true,
                  },
                },
              ]
            : []),
          ...(this.httpUrl
            ? [
                {
                  text: __('HTTPS'),
                  href: `${baseUrl}${this.httpUrlEncoded}`,
                  extraAttrs: {
                    isUnsafeLink: true,
                  },
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
    <gl-disclosure-dropdown-group v-if="groups.sshUrl.show" :bordered="groups.sshUrl.bordered">
      <code-dropdown-clone-item
        :label="__('Clone with SSH')"
        :link="sshUrl"
        name="ssh_project_clone"
        input-id="copy-ssh-url-input"
        test-id="copy-ssh-url-button"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="groups.httpUrl.show" :bordered="groups.httpUrl.bordered">
      <code-dropdown-clone-item
        :label="httpLabel"
        :link="httpUrl"
        name="http_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group
      v-if="groups.kerberosUrl.show"
      :bordered="groups.kerberosUrl.bordered"
    >
      <code-dropdown-clone-item
        :label="__('Clone with KRB5')"
        :link="kerberosUrl"
        name="kerberos_project_clone"
        input-id="copy-http-url-input"
        test-id="copy-http-url-button"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="groups.ideGroup.show" :bordered="groups.ideGroup.bordered">
      <template #group-label>{{ __('Open with') }}</template>
      <code-dropdown-ide-item
        v-for="(item, index) in ideGroup"
        :key="index"
        :ide-item="item"
        :label="__('Open with')"
        @close-dropdown="closeDropdown"
      />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group
      v-if="groups.downloadSourceCode.show"
      :bordered="groups.downloadSourceCode.bordered"
    >
      <template #group-label>{{ __('Download source code') }}</template>
      <code-dropdown-download-items :items="sourceCodeGroup" @close-dropdown="closeDropdown" />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group
      v-if="groups.downloadDirectory.show"
      :bordered="groups.downloadDirectory.bordered"
    >
      <template #group-label>{{ __('Download directory') }}</template>
      <code-dropdown-download-items
        :items="directoryDownloadGroup"
        @close-dropdown="closeDropdown"
      />
    </gl-disclosure-dropdown-group>
    <slot name="gl-ee-compact-code-dropdown"></slot>
  </gl-disclosure-dropdown>
</template>
<style>
/* Temporary override until we have
   * widths available in GlDisclosureDropdown
   * https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/issues/2439
   */
.code-dropdown .gl-new-dropdown-panel {
  width: 100%;
  max-width: 348px;
}
</style>
