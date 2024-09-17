<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  name: 'BranchMoreActions',
  components: { GlDisclosureDropdown },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    branchName: {
      type: String,
      required: true,
    },
    defaultBranchName: {
      type: String,
      required: true,
    },
    canDeleteBranch: {
      type: Boolean,
      required: true,
    },
    isProtectedBranch: {
      type: Boolean,
      required: true,
    },
    merged: {
      type: Boolean,
      required: true,
    },
    comparePath: {
      type: String,
      required: true,
    },
    deletePath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    toggleText: __('More actions'),
    compare: s__('Branches|Compare'),
    deleteBranch: s__('Branches|Delete branch'),
    deleteProtectedBranch: s__('Branches|Delete protected branch'),
  },
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    deleteBranchText() {
      return this.isProtectedBranch
        ? this.$options.i18n.deleteProtectedBranch
        : this.$options.i18n.deleteBranch;
    },
    dropdownItems() {
      const items = [
        {
          text: this.$options.i18n.compare,
          href: this.comparePath,
          extraAttrs: {
            class: 'js-onboarding-compare-branches',
            'data-testid': 'compare-branch-button',
            'data-method': 'post',
          },
        },
      ];

      if (this.canDeleteBranch) {
        items.push({
          text: this.deleteBranchText,
          action: () => {
            this.openModal();
          },
          extraAttrs: {
            class: 'js-delete-branch-button !gl-text-red-500',
            'aria-label': this.deleteBranchText,
            'data-testid': 'delete-branch-button',
          },
        });
      }

      return items;
    },
    moreActionsTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.toggleText : '';
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', {
        branchName: this.branchName,
        defaultBranchName: this.defaultBranchName,
        deletePath: this.deletePath,
        isProtectedBranch: this.isProtectedBranch,
        merged: this.merged,
      });
    },
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.top.viewport="moreActionsTooltip"
    :items="dropdownItems"
    :toggle-text="$options.i18n.toggleText"
    icon="ellipsis_v"
    category="tertiary"
    placement="bottom-end"
    data-testid="branch-more-actions"
    text-sr-only
    no-caret
    @shown="showDropdown"
    @hidden="hideDropdown"
  />
</template>
