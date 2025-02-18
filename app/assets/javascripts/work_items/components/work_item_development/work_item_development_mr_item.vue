<script>
import {
  GlLink,
  GlIcon,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlBadge,
} from '@gitlab/ui';
import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import TooltipOnTruncate from '~/vue_shared/directives/tooltip_on_truncate';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { s__, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';

export default {
  components: {
    GlLink,
    GlIcon,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
    ItemMilestone,
    CiIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlBadge,
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
  },
  computed: {
    assignees() {
      return this.itemContent?.assignees?.nodes || [];
    },
    badgeVariant() {
      return {
        [STATUS_CLOSED]: 'danger',
        [STATUS_MERGED]: 'info',
      };
    },
    badgeLabel() {
      return {
        [STATUS_CLOSED]: s__('WorkItem|Closed'),
        [STATUS_MERGED]: s__('WorkItem|Merged'),
      };
    },
    stateBadgeLabel() {
      return this.badgeLabel[this.itemContent.state];
    },
    stateBadgeVariant() {
      return this.badgeVariant[this.itemContent.state];
    },
    assigneesCollapsedTooltip() {
      if (this.assignees.length > 2) {
        return sprintf(s__('WorkItem|%{count} more assignees'), {
          count: this.assignees.length - 2,
        });
      }
      return '';
    },
    projectPath() {
      return `${this.itemContent.project.namespace.path}/${this.itemContent.project.name}`;
    },
    detailedStatus() {
      return this.itemContent?.headPipeline?.detailedStatus;
    },
    milestone() {
      return this.itemContent?.milestone;
    },
    branchName() {
      return this.itemContent?.sourceBranch;
    },
    mrReference() {
      return this.itemContent?.reference;
    },
    isMRClosed() {
      return this.itemContent.state === STATUS_CLOSED;
    },
    isMRMerged() {
      return this.itemContent.state === STATUS_MERGED;
    },
    isMergedOrClosed() {
      return this.isMRClosed || this.isMRMerged;
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
      this.$refs.mrMoreActions.close();
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-w-full gl-items-start gl-justify-between">
    <div
      class="flex-xl-nowrap gl-flex gl-min-w-0 gl-grow gl-flex-wrap gl-items-center gl-justify-between gl-gap-2 gl-pr-2"
    >
      <div class="item-title gl-flex gl-min-w-0 gl-items-center gl-gap-3">
        <gl-icon
          name="merge-request"
          :size="16"
          variant="default"
          class="gl-shrink-0"
          :class="{ 'gl-fill-icon-subtle': isMRClosed }"
        />
        <gl-link
          v-tooltip-on-truncate
          :href="itemContent.webUrl"
          class="gl-truncate gl-font-semibold gl-text-gray-900 hover:gl-text-gray-900 hover:gl-underline"
          :class="{ 'gl-text-subtle': isMRClosed }"
        >
          {{ itemContent.title }}
        </gl-link>
      </div>
      <div class="item-info-area gl-flex gl-shrink-0 gl-grow gl-gap-3">
        <div class="item-meta gl-flex gl-grow gl-flex-wrap-reverse gl-gap-3 sm:gl-justify-between">
          <div class="item-path-area item-path-id gl-flex gl-flex-wrap gl-items-center gl-gap-3">
            <span class="gl-font-sm gl-text-subtle"> !{{ itemContent.iid }} </span>
            <item-milestone
              v-if="milestone"
              :milestone="milestone"
              class="gl-hidden gl-cursor-help gl-text-subtle sm:gl-block"
            />
          </div>
          <div class="item-attributes-area gl-flex gl-items-center gl-gap-3">
            <div
              class="item-assignees order-md-2 gl-flex gl-shrink-0 gl-items-center gl-gap-3 gl-self-end"
            >
              <gl-badge v-if="isMergedOrClosed" :variant="stateBadgeVariant">
                {{ stateBadgeLabel }}
              </gl-badge>
              <ci-icon v-if="detailedStatus" :status="detailedStatus" />
              <gl-avatars-inline
                v-if="assignees.length"
                :avatars="assignees"
                collapsed
                :max-visible="2"
                :avatar-size="16"
                badge-tooltip-prop="name"
                :badge-sr-only-text="assigneesCollapsedTooltip"
              >
                <template #avatar="{ avatar }">
                  <gl-avatar-link v-gl-tooltip :href="avatar.webUrl" :title="avatar.name">
                    <gl-avatar :alt="avatar.name" :src="avatar.avatarUrl" :size="16" />
                  </gl-avatar-link>
                </template>
              </gl-avatars-inline>
            </div>
          </div>
        </div>
      </div>
    </div>
    <gl-disclosure-dropdown
      ref="mrMoreActions"
      v-gl-tooltip
      icon="ellipsis_v"
      size="small"
      class="sm:gl-max-w-11/12 -gl-mr-2 gl-grow-0 sm:gl-block sm:gl-align-top"
      data-testid="work-item-mr-actions-dropdown"
      text-sr-only
      :toggle-text="__('More actions')"
      category="tertiary"
      :auto-close="false"
      no-caret
      placement="bottom-end"
    >
      <gl-disclosure-dropdown-item
        data-testid="mr-copy-branch-name"
        :data-clipboard-text="branchName"
        @action="copyToClipboard(branchName, __('Copied branch name.'))"
      >
        <template #list-item>{{ __('Copy branch name') }}</template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        data-testid="mr-copy-reference"
        :data-clipboard-text="mrReference"
        @action="copyToClipboard(mrReference, __('Copied reference.'))"
      >
        <template #list-item>{{ __('Copy reference') }}</template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </div>
</template>
