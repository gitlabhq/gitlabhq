<script>
import {
  GlButton,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
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
    GlDisclosureDropdownGroup,
    GlDisclosureDropdown,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'isGroup',
    'groupOrProjectId',
    'leavePath',
    'leaveConfirmMessage',
    'withdrawPath',
    'withdrawConfirmMessage',
    'requestAccessPath',
    'canEdit',
    'editPath',
  ],
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    namespaceType() {
      return this.isGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    hasPath() {
      return this.leavePath || this.withdrawPath || this.requestAccessPath;
    },
    settingsTitle() {
      return this.isGroup ? this.$options.i18n.groupSettings : this.$options.i18n.projectSettings;
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
          class: '!gl-text-danger js-leave-link',
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
        text: sprintf(this.copyTitle, { id: this.groupOrProjectId }),
        action: () => {
          this.$toast.show(this.copiedToClipboard);
        },
        extraAttrs: {
          'data-testid': `copy-${this.namespaceType}-id`,
        },
      };
    },
    settingsItem() {
      return {
        text: this.settingsTitle,
        href: this.editPath,
        extraAttrs: {
          'data-testid': `settings-${this.namespaceType}-link`,
        },
      };
    },
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.actionsLabel : '';
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
  i18n: {
    actionsLabel: __('More actions'),
    groupCopiedToClipboard: s__('GroupPage|Group ID copied to clipboard.'),
    projectCopiedToClipboard: s__('ProjectPage|Project ID copied to clipboard.'),
    groupLeaveTitle: __('Leave group'),
    projectLeaveTitle: __('Leave project'),
    withdrawAccessTitle: __('Withdraw Access Request'),
    requestAccessTitle: __('Request Access'),
    groupCopyTitle: s__('GroupPage|Copy group ID: %{id}'),
    projectCopyTitle: s__('ProjectPage|Copy project ID: %{id}'),
    projectSettings: s__('ProjectPage|Project settings'),
    groupSettings: s__('GroupPage|Group settings'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip="showDropdownTooltip"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    :toggle-text="$options.i18n.actionsLabel"
    text-sr-only
    data-testid="groups-projects-more-actions-dropdown"
    class="gl-relative gl-w-full sm:gl-w-auto"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template #toggle>
      <div class="gl-min-h-7">
        <gl-button
          class="gl-new-dropdown-toggle gl-absolute gl-left-0 gl-top-0 gl-w-full sm:gl-w-auto md:!gl-hidden"
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
          class="gl-new-dropdown-toggle gl-new-dropdown-icon-only gl-new-dropdown-toggle-no-caret gl-hidden md:!gl-flex"
          category="tertiary"
          icon="ellipsis_v"
          :aria-label="$options.i18n.actionsLabel"
          :title="$options.i18n.actionsLabel"
        />
      </div>
    </template>

    <gl-disclosure-dropdown-item
      v-if="groupOrProjectId"
      :item="copyIdItem"
      :data-clipboard-text="groupOrProjectId"
    />
    <gl-disclosure-dropdown-item v-if="canEdit" :item="settingsItem" />

    <gl-disclosure-dropdown-group v-if="hasPath" bordered>
      <gl-disclosure-dropdown-item v-if="leavePath" ref="leaveItem" :item="leaveItem" />
      <gl-disclosure-dropdown-item v-else-if="withdrawPath" :item="withdrawItem" />
      <gl-disclosure-dropdown-item v-else-if="requestAccessPath" :item="requestAccessItem" />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
