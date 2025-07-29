<script>
import {
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlLink,
} from '@gitlab/ui';
import { isMetaClick } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __, s__, sprintf } from '~/locale';
import {
  TOP_NAV_INVITE_MEMBERS_COMPONENT,
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
} from '~/invite_members/constants';
import {
  BASE_ALLOWED_CREATE_TYPES,
  CREATE_NEW_WORK_ITEM_MODAL,
  NAME_TO_TEXT_MAP,
  WORK_ITEM_TYPE_NAME_EPIC,
} from '~/work_items/constants';
import { DROPDOWN_Y_OFFSET, IMPERSONATING_OFFSET } from '../constants';

// Left offset required for the dropdown to be aligned with the super sidebar
const DROPDOWN_X_OFFSET_BASE = -177;
const DROPDOWN_X_OFFSET_IMPERSONATING = DROPDOWN_X_OFFSET_BASE + IMPERSONATING_OFFSET;

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlLink,
    InviteMembersTrigger,
    CreateWorkItemModal: () => import('~/work_items/components/create_work_item_modal.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    createNew: __('Create new…'),
  },
  inject: ['isGroup', 'isImpersonating', 'fullPath', 'workItemPlanningViewEnabled'],
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dropdownOpen: false,
      showCreateWorkItemModal: false,
    };
  },
  computed: {
    allowedWorkItemTypes() {
      if (this.isGroup) {
        return [];
      }
      return BASE_ALLOWED_CREATE_TYPES;
    },
    dropdownOffset() {
      return {
        mainAxis: DROPDOWN_Y_OFFSET,
        crossAxis: this.isImpersonating ? DROPDOWN_X_OFFSET_IMPERSONATING : DROPDOWN_X_OFFSET_BASE,
      };
    },
    preselectedWorkItemType() {
      return !this.workItemPlanningViewEnabled && this.isGroup
        ? WORK_ITEM_TYPE_NAME_EPIC
        : undefined;
    },
  },
  methods: {
    isInvitedMembers(groupItem) {
      return groupItem.component === TOP_NAV_INVITE_MEMBERS_COMPONENT;
    },
    isCreateWorkItem(groupItem) {
      return groupItem.component === CREATE_NEW_WORK_ITEM_MODAL;
    },
    getCreateWorkItemItem(groupItem) {
      // Make sure <gl-disclosure-dropdown-item> doesn't have an href so it's
      // not rendered as <a> which prevents us from opening the create modal
      return { ...groupItem, href: undefined };
    },
    getCreateWorkItemHref(groupItem) {
      return this.workItemPlanningViewEnabled ? undefined : groupItem.href;
    },
    handleCreateWorkItemClick(event) {
      if (event && isMetaClick(event)) {
        // opening in a new tab
        return;
      }

      // don't follow the link for normal clicks - open in modal
      event?.preventDefault?.();

      this.showCreateWorkItemModal = true;
    },
    handleWorkItemCreated(workItem) {
      // Triggering the toast at this component, because we want to lazy load the modal
      // with `v-if` and by doing that the modal is destroyed before the toast
      // from the modal component can be triggered

      // Hide the modal first to prevent the component from being destroyed
      // before we can capture the event data
      this.showCreateWorkItemModal = false;

      const message = sprintf(s__('WorkItem|%{workItemType} created'), {
        workItemType: NAME_TO_TEXT_MAP[workItem?.workItemType?.name],
      });

      this.$toast.show(message, {
        autoHideDelay: 10000,
        action: {
          text: __('View details'),
          onClick: () => visitUrl(workItem?.webUrl),
        },
      });
    },
  },
  toggleId: 'create-menu-toggle',
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
  WORK_ITEM_TYPE_NAME_EPIC,
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip:super-sidebar.bottom="dropdownOpen ? '' : $options.i18n.createNew"
    category="tertiary"
    icon="plus"
    no-caret
    text-sr-only
    :toggle-text="$options.i18n.createNew"
    :toggle-id="$options.toggleId"
    :dropdown-offset="dropdownOffset"
    data-testid="new-menu-toggle"
    @shown="dropdownOpen = true"
    @hidden="dropdownOpen = false"
  >
    <gl-disclosure-dropdown-group
      v-for="(group, index) in groups"
      :key="group.name"
      :bordered="index !== 0"
      :group="group"
    >
      <template v-for="groupItem in group.items">
        <invite-members-trigger
          v-if="isInvitedMembers(groupItem)"
          :key="`${groupItem.text}-trigger`"
          trigger-source="top_nav"
          :trigger-element="$options.TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN"
        />
        <gl-disclosure-dropdown-item
          v-else-if="isCreateWorkItem(groupItem)"
          :key="`${groupItem.text}-modal-trigger`"
          :item="getCreateWorkItemItem(groupItem)"
          data-testid="new-work-item-trigger"
          @action="handleCreateWorkItemClick"
        >
          <template #list-item>
            <gl-link
              v-if="getCreateWorkItemHref(groupItem)"
              class="gl-block gl-text-default hover:gl-text-default hover:gl-no-underline"
              :href="getCreateWorkItemHref(groupItem)"
              @click.stop="handleCreateWorkItemClick"
            >
              {{ groupItem.text }}
            </gl-link>
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item v-else :key="groupItem.text" :item="groupItem" />
      </template>
    </gl-disclosure-dropdown-group>
    <create-work-item-modal
      v-if="showCreateWorkItemModal"
      :allowed-work-item-types="allowedWorkItemTypes"
      :always-show-work-item-type-select="!isGroup"
      :full-path="fullPath"
      hide-button
      :is-group="isGroup"
      :preselected-work-item-type="preselectedWorkItemType"
      visible
      data-testid="new-work-item-modal"
      @hideModal="showCreateWorkItemModal = false"
      @workItemCreated="handleWorkItemCreated"
    />
  </gl-disclosure-dropdown>
</template>
