<script>
import {
  GlIcon,
  GlLink,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlDropdownDivider,
} from '@gitlab/ui';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/directives/tooltip_on_truncate';
import toast from '~/vue_shared/plugins/global_toast';
import { visitUrl } from '~/lib/utils/url_utility';
import { createBranchMRApiPathHelper } from '~/work_items/utils';

export default {
  components: {
    GlIcon,
    GlLink,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDropdownDivider,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    TooltipOnTruncate,
  },
  props: {
    itemContent: {
      type: Object,
      required: true,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateMergeRequest: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
  },
  computed: {
    branchName() {
      return this.itemContent?.name;
    },
    branchComparePath() {
      return this.itemContent?.comparePath;
    },
    iconTooltip() {
      return __('Branch');
    },
  },
  methods: {
    copyToClipboard(text, message) {
      if (this.isModal) {
        navigator.clipboard.writeText(text);
      }
      toast(message);
      this.closeDropdown();
    },
    closeDropdown() {
      this.$refs.branchMoreActions.close();
    },
    createMergeRequest() {
      const path = createBranchMRApiPathHelper.createMR({
        fullPath: this.workItemFullPath,
        workItemIid: this.workItemIid,
        sourceBranch: this.branchName,
      });

      visitUrl(path);
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-w-full gl-justify-between gl-gap-3">
    <div class="flex-xl-nowrap gl-flex gl-w-19/20 gl-flex-wrap gl-items-center gl-gap-3">
      <gl-icon
        v-gl-tooltip
        :title="iconTooltip"
        name="branch"
        variant="default"
        class="gl-shrink-0"
      />
      <gl-link
        v-tooltip-on-truncate
        :href="branchComparePath"
        class="gl-max-w-17/20 gl-truncate gl-font-semibold gl-text-primary hover:gl-text-primary hover:gl-underline"
      >
        {{ branchName }}
      </gl-link>
    </div>
    <gl-disclosure-dropdown
      ref="branchMoreActions"
      icon="ellipsis_v"
      data-testid="work-item-branch-actions-dropdown"
      size="small"
      class="gl-float-right -gl-mr-2"
      text-sr-only
      :toggle-text="__('More actions')"
      category="tertiary"
      :auto-close="false"
      no-caret
      placement="bottom-end"
    >
      <gl-disclosure-dropdown-item
        v-if="canCreateMergeRequest"
        data-testid="branch-create-merge-request"
        @action="createMergeRequest"
      >
        <template #list-item>{{ __('Create merge request') }}</template>
      </gl-disclosure-dropdown-item>
      <gl-dropdown-divider v-if="canCreateMergeRequest" />
      <gl-disclosure-dropdown-item
        data-testid="branch-copy-name"
        :data-clipboard-text="branchName"
        @action="copyToClipboard(branchName, __('Copied branch.'))"
      >
        <template #list-item>{{ __('Copy branch name') }}</template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </div>
</template>
