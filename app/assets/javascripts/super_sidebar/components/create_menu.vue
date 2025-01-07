<script>
import {
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';
import {
  TOP_NAV_INVITE_MEMBERS_COMPONENT,
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
} from '~/invite_members/constants';
import { WORK_ITEM_TYPE_ENUM_EPIC, CREATE_NEW_WORK_ITEM_MODAL } from '~/work_items/constants';
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
    createNew: __('Create new...'),
  },
  inject: ['isImpersonating'],
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
  },
  toggleId: 'create-menu-toggle',
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
  WORK_ITEM_TYPE_ENUM_EPIC,
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
          :item="groupItem"
          @action="showCreateWorkItemModal = true"
        />
        <gl-disclosure-dropdown-item v-else :key="groupItem.text" :item="groupItem" />
      </template>
    </gl-disclosure-dropdown-group>
    <create-work-item-modal
      v-if="showCreateWorkItemModal"
      visible
      hide-button
      is-group
      :work-item-type-name="$options.WORK_ITEM_TYPE_ENUM_EPIC"
      @hideModal="showCreateWorkItemModal = false"
    />
  </gl-disclosure-dropdown>
</template>
