<script>
import {
  GlButton,
  GlDisclosureDropdownItem,
  GlDisclosureDropdown,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

export default {
  components: {
    GlButton,
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'isGroup',
    'id',
    'leavePath',
    'leaveConfirmMessage',
    'withdrawPath',
    'withdrawConfirmMessage',
    'requestAccessPath',
  ],
  computed: {
    namespaceType() {
      return this.isGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    leaveTitle() {
      return this.isGroup
        ? this.$options.i18n.groupLeaveTitle
        : this.$options.i18n.projectLeaveTitle;
    },
    copyTitle() {
      return this.isGroup ? this.$options.i18n.groupCopyTitle : this.$options.i18n.projectCopyTitle;
    },
    copiedToClipboard() {
      return this.isGroup
        ? this.$options.i18n.groupCopiedToClipboard
        : this.$options.i18n.projectCopiedToClipboard;
    },
    leaveItem() {
      return {
        text: this.leaveTitle,
        href: this.leavePath,
        extraAttrs: {
          'aria-label': this.leaveTitle,
          'data-method': 'delete',
          'data-confirm': this.leaveConfirmMessage,
          'data-confirm-btn-variant': 'danger',
          'data-testid': `leave-${this.namespaceType}-link`,
          rel: 'nofollow',
          class: 'gl-text-red-500! js-leave-link',
        },
      };
    },
    withdrawItem() {
      return {
        text: this.$options.i18n.withdrawAccessTitle,
        href: this.withdrawPath,
        extraAttrs: {
          'data-method': 'delete',
          'data-confirm': this.withdrawConfirmMessage,
          'data-testid': 'withdraw-access-link',
          rel: 'nofollow',
        },
      };
    },
    requestAccessItem() {
      return {
        text: this.$options.i18n.requestAccessTitle,
        href: this.requestAccessPath,
        extraAttrs: {
          'data-method': 'post',
          'data-testid': 'request-access-link',
          rel: 'nofollow',
        },
      };
    },
    copyIdItem() {
      return {
        text: sprintf(this.copyTitle, { id: this.id }),
        action: () => {
          this.$toast.show(this.copiedToClipboard);
        },
        extraAttrs: {
          'data-testid': `copy-${this.namespaceType}-id`,
        },
      };
    },
  },
  i18n: {
    actionsLabel: __('Actions'),
    groupCopiedToClipboard: s__('GroupPage|Group ID copied to clipboard.'),
    projectCopiedToClipboard: s__('ProjectPage|Project ID copied to clipboard.'),
    groupLeaveTitle: __('Leave group'),
    projectLeaveTitle: __('Leave project'),
    withdrawAccessTitle: __('Withdraw Access Request'),
    requestAccessTitle: __('Request Access'),
    groupCopyTitle: s__('GroupPage|Copy group ID: %{id}'),
    projectCopyTitle: s__('ProjectPage|Copy project ID: %{id}'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.hover="$options.i18n.actionsLabel"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    :toggle-text="$options.i18n.actionsLabel"
    text-sr-only
    data-testid="groups-projects-more-actions-dropdown"
    class="gl-relative gl-w-full gl-sm-w-auto"
  >
    <template #toggle>
      <div class="gl-min-h-7">
        <gl-button
          class="gl-md-display-none! gl-new-dropdown-toggle gl-absolute gl-top-0 gl-left-0 gl-w-full gl-sm-w-auto"
          button-text-classes="gl-w-full"
          category="secondary"
          :aria-label="$options.i18n.actionsLabel"
          :title="$options.i18n.actionsLabel"
        >
          <span class="gl-new-dropdown-button-text">{{ $options.i18n.actionsLabel }}</span>
          <gl-icon class="dropdown-chevron" name="chevron-down" />
        </gl-button>
        <gl-button
          ref="moreActionsDropdown"
          class="gl-display-none gl-md-display-flex! gl-new-dropdown-toggle gl-new-dropdown-icon-only gl-new-dropdown-toggle-no-caret"
          category="tertiary"
          icon="ellipsis_v"
          :aria-label="$options.i18n.actionsLabel"
          :title="$options.i18n.actionsLabel"
        />
      </div>
    </template>

    <gl-disclosure-dropdown-item v-if="leavePath" ref="leaveItem" :item="leaveItem" />

    <gl-disclosure-dropdown-item v-else-if="withdrawPath" :item="withdrawItem" />

    <gl-disclosure-dropdown-item v-else-if="requestAccessPath" :item="requestAccessItem" />

    <gl-disclosure-dropdown-item v-if="id" :item="copyIdItem" :data-clipboard-text="id" />
  </gl-disclosure-dropdown>
</template>
