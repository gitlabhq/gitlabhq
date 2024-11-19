<script>
import {
  GlButton,
  GlIcon,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdown,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import PromoteMilestoneModal from '~/milestones/components/promote_milestone_modal.vue';
import DeleteMilestoneModal from '~/milestones/components/delete_milestone_modal.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdown,
    PromoteMilestoneModal,
    DeleteMilestoneModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'id',
    'title',
    'isActive',
    'showDelete',
    'isDetailPage',
    'milestoneUrl',
    'editUrl',
    'closeUrl',
    'reopenUrl',
    'promoteUrl',
    'groupName',
    'issueCount',
    'mergeRequestCount',
    'size',
  ],
  data() {
    return {
      isDropdownVisible: false,
      isPromotionModalVisible: false,
      isDeleteModalVisible: false,
      isPromoteModalVisible: false,
    };
  },
  computed: {
    widthClasses() {
      return this.size === 'small' ? 'gl-min-w-6' : 'gl-min-w-7';
    },
    hasUrl() {
      return this.editUrl || this.closeUrl || this.reopenUrl || this.promoteUrl;
    },
    copiedToClipboard() {
      return this.$options.i18n.copiedToClipboard;
    },
    editItem() {
      return {
        text: this.$options.i18n.edit,
        href: this.editUrl,
        extraAttrs: {
          'data-testid': 'milestone-edit-item',
        },
      };
    },
    promoteItem() {
      return {
        text: this.$options.i18n.promote,
        extraAttrs: {
          'data-testid': 'milestone-promote-item',
        },
      };
    },
    closeItem() {
      return {
        text: this.$options.i18n.close,
        href: this.closeUrl,
        extraAttrs: {
          class: { 'sm:!gl-hidden': this.isDetailPage },
          'data-testid': 'milestone-close-item',
          'data-method': 'put',
          rel: 'nofollow',
        },
      };
    },
    reopenItem() {
      return {
        text: this.$options.i18n.reopen,
        href: this.reopenUrl,
        extraAttrs: {
          class: { 'sm:!gl-hidden': this.isDetailPage },
          'data-testid': 'milestone-reopen-item',
          'data-method': 'put',
          rel: 'nofollow',
        },
      };
    },
    deleteItem() {
      return {
        text: this.$options.i18n.delete,
        extraAttrs: {
          class: '!gl-text-red-500',
          'data-testid': 'milestone-delete-item',
        },
      };
    },
    copyIdItem() {
      return {
        text: sprintf(this.$options.i18n.copyTitle, { id: this.id }),
        action: () => {
          this.$toast.show(this.copiedToClipboard);
        },
        extraAttrs: {
          'data-testid': 'copy-milestone-id',
          itemprop: 'identifier',
        },
      };
    },
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.actionsLabel : '';
    },
    showTestIdIfNotDetailPage() {
      return !this.isDetailPage ? 'milestone-more-actions-dropdown-toggle' : false;
    },
    hasEditOptions() {
      return Boolean(this.closeUrl || this.reopenUrl || this.editUrl || this.promoteUrl);
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
    setDeleteModalVisibility(visibility = false) {
      this.isDeleteModalVisible = visibility;
    },
    setPromoteModalVisibility(visibility = false) {
      this.isPromoteModalVisible = visibility;
    },
  },
  primaryAction: {
    text: s__('Milestones|Promote Milestone'),
    attributes: { variant: 'confirm' },
  },
  cancelAction: {
    text: __('Cancel'),
    attributes: {},
  },
  i18n: {
    actionsLabel: s__('Milestone|Milestone actions'),
    close: __('Close'),
    delete: __('Delete'),
    edit: __('Edit'),
    promote: __('Promote'),
    reopen: __('Reopen'),
    copyTitle: s__('Milestone|Copy milestone ID: %{id}'),
    copiedToClipboard: s__('Milestone|Milestone ID copied to clipboard.'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip="showDropdownTooltip"
    category="tertiary"
    icon="ellipsis_v"
    placement="bottom-end"
    block
    no-caret
    :toggle-text="$options.i18n.actionsLabel"
    text-sr-only
    class="gl-relative gl-w-full sm:gl-w-auto"
    :class="widthClasses"
    :size="size"
    :data-testid="showTestIdIfNotDetailPage"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template v-if="isDetailPage" #toggle>
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
          class="gl-new-dropdown-toggle gl-new-dropdown-icon-only gl-new-dropdown-toggle-no-caret gl-hidden md:!gl-flex"
          category="tertiary"
          icon="ellipsis_v"
          :aria-label="$options.i18n.actionsLabel"
          :title="$options.i18n.actionsLabel"
          data-testid="milestone-more-actions-dropdown-toggle"
        />
      </div>
    </template>

    <gl-disclosure-dropdown-item v-if="isActive && closeUrl" :item="closeItem" />
    <gl-disclosure-dropdown-item v-else-if="reopenUrl" :item="reopenItem" />

    <gl-disclosure-dropdown-item v-if="editUrl" :item="editItem" />

    <gl-disclosure-dropdown-item
      v-if="promoteUrl"
      :item="promoteItem"
      @action="setPromoteModalVisibility(true)"
    />

    <gl-disclosure-dropdown-group
      :bordered="hasEditOptions"
      :class="{ '!gl-border-t-dropdown': hasEditOptions }"
    >
      <gl-disclosure-dropdown-item :item="copyIdItem" :data-clipboard-text="id" />
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="showDelete" bordered class="!gl-border-t-dropdown">
      <gl-disclosure-dropdown-item :item="deleteItem" @action="setDeleteModalVisibility(true)" />
    </gl-disclosure-dropdown-group>

    <promote-milestone-modal
      :visible="isPromoteModalVisible"
      :milestone-title="title"
      :promote-url="promoteUrl"
      :group-name="groupName"
      @promotionModalVisible="setPromoteModalVisibility"
    />

    <delete-milestone-modal
      :visible="isDeleteModalVisible"
      :issue-count="issueCount"
      :merge-request-count="mergeRequestCount"
      :milestone-id="id"
      :milestone-title="title"
      :milestone-url="milestoneUrl"
      @deleteModalVisible="setDeleteModalVisibility"
    />
  </gl-disclosure-dropdown>
</template>
