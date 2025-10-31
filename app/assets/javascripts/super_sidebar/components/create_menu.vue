<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isMetaClick } from '~/lib/utils/common_utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';
import {
  TOP_NAV_INVITE_MEMBERS_COMPONENT,
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
} from '~/invite_members/constants';
import {
  BASE_ALLOWED_CREATE_TYPES,
  CREATE_NEW_WORK_ITEM_MODAL,
  CREATION_CONTEXT_SUPER_SIDEBAR,
  WORK_ITEM_TYPE_NAME_EPIC,
} from '~/work_items/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DROPDOWN_Y_OFFSET } from '../constants';

// Left offset required for the dropdown to be aligned with the super sidebar
const DROPDOWN_X_OFFSET_BASE = -158;

export default {
  CREATION_CONTEXT_SUPER_SIDEBAR,
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
  mixins: [glFeatureFlagsMixin()],
  inject: ['isGroup', 'fullPath', 'workItemPlanningViewEnabled', 'projectStudioEnabled'],
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dropdownOpen: false,
      isCreateWorkItemModalVisible: false,
      loadCreateWorkItemModal: false,
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
        crossAxis: this.projectStudioEnabled ? -8 : DROPDOWN_X_OFFSET_BASE,
      };
    },
    isEpicsList() {
      // If consolidated list is disabled and is group
      // New epic is show which is similar to epic list experience
      return !this.workItemPlanningViewEnabled && this.isGroup;
    },
    preselectedWorkItemType() {
      return this.isEpicsList ? WORK_ITEM_TYPE_NAME_EPIC : undefined;
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

      this.loadCreateWorkItemModal = true;
      this.isCreateWorkItemModalVisible = true;
    },
  },
  toggleId: 'create-menu-toggle',
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
  WORK_ITEM_TYPE_NAME_EPIC,
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.bottom="dropdownOpen ? '' : $options.i18n.createNew"
    category="tertiary"
    :icon="projectStudioEnabled ? 'plus-square-o' : 'plus'"
    no-caret
    text-sr-only
    :toggle-text="$options.i18n.createNew"
    :toggle-id="$options.toggleId"
    :dropdown-offset="dropdownOffset"
    class="super-sidebar-new-menu-dropdown"
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
      v-if="loadCreateWorkItemModal"
      :allowed-work-item-types="allowedWorkItemTypes"
      :always-show-work-item-type-select="!isGroup"
      :creation-context="$options.CREATION_CONTEXT_SUPER_SIDEBAR"
      :full-path="fullPath"
      hide-button
      :is-group="isGroup"
      :preselected-work-item-type="preselectedWorkItemType"
      :visible="isCreateWorkItemModalVisible"
      :is-epics-list="isEpicsList"
      from-global-menu
      data-testid="new-work-item-modal"
      @hideModal="isCreateWorkItemModalVisible = false"
    />
  </gl-disclosure-dropdown>
</template>
