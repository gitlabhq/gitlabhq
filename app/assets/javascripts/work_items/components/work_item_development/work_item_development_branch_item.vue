<script>
import { GlIcon, GlLink, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/directives/tooltip_on_truncate';
import toast from '~/vue_shared/plugins/global_toast';

export default {
  components: {
    GlIcon,
    GlLink,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
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
  },
  computed: {
    branchName() {
      return this.itemContent?.name;
    },
    branchComparePath() {
      return this.itemContent?.comparePath;
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
  },
};
</script>

<template>
  <div class="gl-flex gl-w-full gl-justify-between">
    <div class="flex-xl-nowrap gl-flex gl-w-19/20 gl-flex-wrap gl-items-center gl-gap-2">
      <gl-icon name="branch" variant="default" class="gl-shrink-0" />
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
        data-testid="branch-copy-name"
        :data-clipboard-text="branchName"
        @action="copyToClipboard(branchName, __('Copied branch.'))"
      >
        <template #list-item>{{ __('Copy branch name') }}</template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </div>
</template>
