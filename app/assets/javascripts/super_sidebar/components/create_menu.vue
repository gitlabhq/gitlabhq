<script>
import {
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __, s__ } from '~/locale';
import {
  TOP_NAV_INVITE_MEMBERS_COMPONENT,
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
} from '~/invite_members/constants';
import {
  WORK_ITEM_TYPE_NAME_EPIC,
  CREATE_NEW_WORK_ITEM_MODAL,
  CREATE_NEW_GROUP_WORK_ITEM_MODAL,
  NAME_TO_TEXT_LOWERCASE_MAP,
  sprintfWorkItem,
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
    InviteMembersTrigger,
    CreateWorkItemModal: () => import('~/work_items/components/create_work_item_modal.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    createNew: __('Create new…'),
  },
  inject: ['isImpersonating', 'fullPath', 'workItemPlanningViewEnabled'],
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dropdownOpen: false,
      showCreateGroupWorkItemModal: false,
      showCreateWorkItemModal: false,
    };
  },
  computed: {
    dropdownOffset() {
      return {
        mainAxis: DROPDOWN_Y_OFFSET,
        crossAxis: this.isImpersonating ? DROPDOWN_X_OFFSET_IMPERSONATING : DROPDOWN_X_OFFSET_BASE,
      };
    },
  },
  methods: {
    isInvitedMembers(groupItem) {
      return groupItem.component === TOP_NAV_INVITE_MEMBERS_COMPONENT;
    },
    isCreateWorkItem(groupItem) {
      return groupItem.component === CREATE_NEW_WORK_ITEM_MODAL;
    },
    isCreateGroupWorkItem(groupItem) {
      return groupItem.component === CREATE_NEW_GROUP_WORK_ITEM_MODAL;
    },
    handleCreateWorkItemClick() {
      if (this.workItemPlanningViewEnabled) {
        this.showCreateWorkItemModal = true;
      } else {
        this.showCreateGroupWorkItemModal = true;
      }
    },
    handleWorkItemCreated(workItem) {
      // Triggering the toast at this component, because we want to lazy load the modal
      // with `v-if` and by doing that the modal is destroyed before the toast
      // from the modal component can be triggered

      // Hide the modal first to prevent the component from being destroyed
      // before we can capture the event data
      this.showCreateGroupWorkItemModal = false;
      this.showCreateWorkItemModal = false;

      const workItemType = NAME_TO_TEXT_LOWERCASE_MAP[workItem?.workItemType?.name];
      const message = sprintfWorkItem(s__('WorkItem|%{workItemType} created'), workItemType);

      // Display the toast
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
          v-else-if="isCreateGroupWorkItem(groupItem)"
          :key="`${groupItem.text}-group-modal-trigger`"
          :item="groupItem"
          data-testid="new-group-work-item-trigger"
          @action="showCreateGroupWorkItemModal = true"
        />
        <gl-disclosure-dropdown-item
          v-else-if="isCreateWorkItem(groupItem)"
          :key="`${groupItem.text}-modal-trigger`"
          :item="groupItem"
          data-testid="new-work-item-trigger"
          @action="handleCreateWorkItemClick"
        />
        <gl-disclosure-dropdown-item v-else :key="groupItem.text" :item="groupItem" />
      </template>
    </gl-disclosure-dropdown-group>
    <create-work-item-modal
      v-if="showCreateGroupWorkItemModal"
      visible
      hide-button
      is-group
      data-testid="new-group-work-item-modal"
      :preselected-work-item-type="$options.WORK_ITEM_TYPE_NAME_EPIC"
      @hideModal="showCreateGroupWorkItemModal = false"
      @workItemCreated="handleWorkItemCreated"
    />
    <create-work-item-modal
      v-if="showCreateWorkItemModal"
      visible
      hide-button
      data-testid="new-work-item-modal"
      :full-path="fullPath"
      @hideModal="showCreateWorkItemModal = false"
      @workItemCreated="handleWorkItemCreated"
    />
  </gl-disclosure-dropdown>
</template>
