<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'CodeDropdown',
  components: {
    GlDisclosureDropdown,
  },
  props: {
    webIdePath: {
      type: String,
      required: false,
      default: '',
    },
    gitpodPath: {
      type: String,
      required: false,
      default: '',
    },
    workspacePath: {
      type: String,
      required: false,
      default: '',
    },
    workspaceEventLabel: {
      type: String,
      required: false,
      default: '',
    },
    patchesPath: {
      type: String,
      required: true,
    },
    plainDiffPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    items() {
      return [
        {
          name: __('Review changes'),
          items: [
            {
              text: __('Check out branch'),
              extraAttrs: { class: 'js-check-out-modal-trigger' },
            },
            this.webIdePath && {
              text: __('Open in Web IDE'),
              href: this.webIdePath,
              extraAttrs: { target: '_blank', 'data-testid': 'open-in-web-ide-button' },
            },
            this.gitpodPath && {
              text: __('Open in Ona'),
              href: this.gitpodPath,
              extraAttrs: { target: '_blank' },
            },
            this.workspacePath && {
              text: __('Open in Workspace'),
              href: this.workspacePath,
              extraAttrs: {
                target: '_blank',
                'data-testid': 'open-in-workspace-button',
                'data-event-tracking': 'click_new_workspace_button',
                'data-event-label': this.workspaceEventLabel,
              },
            },
          ].filter(Boolean),
        },
        {
          name: __('Download'),
          items: [
            {
              text: __('Patches'),
              href: this.patchesPath,
              extraAttrs: { download: '', 'data-testid': 'download-email-patches-menu-item' },
            },
            {
              text: __('Plain diff'),
              href: this.plainDiffPath,
              extraAttrs: { download: '', 'data-testid': 'download-plain-diff-menu-item' },
            },
          ],
        },
      ];
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :toggle-text="__('Code')"
    :items="items"
    placement="bottom-end"
    class="gl-w-full gl-align-top gl-leading-normal"
    toggle-class="gl-w-full @sm/panel:gl-w-auto"
    data-testid="mr-code-dropdown"
  />
</template>
