<script>
import { GlIcon, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';

import { createAlert } from '~/alert';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import axios from '~/lib/utils/axios_utils';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { __ } from '~/locale';
import { numberToMetricPrefix, numberToHumanSize, isNumeric } from '~/lib/utils/number_utils';
import {
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';
import { renderDeleteSuccessToast, deleteParams } from '~/vue_shared/components/groups_list/utils';
import GroupListItemLeaveModal from '~/vue_shared/components/groups_list/group_list_item_leave_modal.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import GroupListItemInactiveBadge from './group_list_item_inactive_badge.vue';

export default {
  i18n: {
    subgroups: __('Subgroups'),
    projects: __('Projects'),
    directMembers: __('Direct members'),
    deleteErrorMessage: __(
      'An error occurred deleting the group. Please refresh the page to try again.',
    ),
  },
  components: {
    ListItem,
    ListItemStat,
    GlIcon,
    GlBadge,
    GroupListItemActions,
    GroupListItemLeaveModal,
    GroupListItemPreventDeleteModal,
    GroupListItemDeleteModal,
    GroupListItemInactiveBadge,
    GroupsListItemPlanBadge: () =>
      import('ee_component/vue_shared/components/groups_list/groups_list_item_plan_badge.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    showGroupIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    listItemClass: {
      type: [String, Array, Object],
      required: false,
      default: '',
    },
    timestampType: {
      type: String,
      required: false,
      default: TIMESTAMP_TYPE_CREATED_AT,
      validator(value) {
        return TIMESTAMP_TYPES.includes(value);
      },
    },
  },
  data() {
    return {
      isDeleteModalVisible: false,
      isDeleteModalLoading: false,
      isLeaveModalVisible: false,
      modalId: uniqueId('groups-list-item-modal-id-'),
    };
  },
  computed: {
    visibility() {
      return this.group.visibility;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.visibility];
    },
    accessLevel() {
      return this.group.accessLevel?.integerValue;
    },
    accessLevelLabel() {
      return ACCESS_LEVEL_LABELS[this.accessLevel];
    },
    shouldShowAccessLevel() {
      const falsyValues = [undefined, null, ACCESS_LEVEL_NO_ACCESS_INTEGER];

      return !falsyValues.includes(this.accessLevel);
    },
    groupIconName() {
      return this.group.parent ? 'subgroup' : 'group';
    },
    descendantGroupsCount() {
      return numberToMetricPrefix(this.group.descendantGroupsCount);
    },
    projectsCount() {
      return numberToMetricPrefix(this.group.projectsCount);
    },
    groupMembersCount() {
      return numberToMetricPrefix(this.group.groupMembersCount);
    },
    showDescendantGroupsCount() {
      return isNumeric(this.group.descendantGroupsCount);
    },
    showProjectsCount() {
      return isNumeric(this.group.projectsCount);
    },
    showGroupMembersCount() {
      return isNumeric(this.group.groupMembersCount);
    },
    storageSize() {
      if (!this.hasStorageSize) {
        return null;
      }

      return numberToHumanSize(this.group.rootStorageStatistics?.storageSize || 0);
    },
    hasStorageSize() {
      return Object.hasOwn(this.group, 'rootStorageStatistics');
    },
    hasActionDelete() {
      return (
        this.group.availableActions?.includes(ACTION_DELETE) ||
        this.group.availableActions?.includes(ACTION_DELETE_IMMEDIATELY)
      );
    },
    hasActionLeave() {
      return this.group.availableActions?.includes(ACTION_LEAVE);
    },
    hasActions() {
      return this.group.availableActions?.length;
    },
    hasFooterAction() {
      return this.hasActionDelete || this.hasActionLeave;
    },
    dataTestid() {
      return `groups-list-item-${this.group.id}`;
    },
  },
  methods: {
    onActionDelete() {
      this.isDeleteModalVisible = true;
    },
    onDeleteModalChange(isVisible) {
      this.isDeleteModalVisible = isVisible;
    },
    async onDeleteModalConfirm() {
      this.isDeleteModalLoading = true;

      try {
        await axios.delete(this.group.webUrl, {
          params: deleteParams(this.group),
        });
        this.refetch();
        renderDeleteSuccessToast(this.group);
      } catch (error) {
        createAlert({ message: this.$options.i18n.deleteErrorMessage, error, captureError: true });
      } finally {
        this.isDeleteModalLoading = false;
      }
    },
    onActionLeave() {
      this.isLeaveModalVisible = true;
    },
    refetch() {
      this.$emit('refetch');
    },
  },
};
</script>

<template>
  <list-item
    :resource="group"
    :show-icon="showGroupIcon"
    :icon-name="groupIconName"
    :list-item-class="listItemClass"
    :timestamp-type="timestampType"
    :data-testid="dataTestid"
  >
    <template #children-toggle>
      <slot name="children-toggle"></slot>
    </template>
    <template #avatar-meta>
      <gl-icon
        v-if="visibility"
        v-gl-tooltip="visibilityTooltip"
        :name="visibilityIcon"
        variant="subtle"
      />
      <gl-badge v-if="shouldShowAccessLevel" class="gl-block" data-testid="user-access-role">{{
        accessLevelLabel
      }}</gl-badge>
    </template>

    <template #stats>
      <group-list-item-inactive-badge :group="group" />
      <gl-badge v-if="hasStorageSize" data-testid="storage-size">{{ storageSize }}</gl-badge>
      <groups-list-item-plan-badge :group="group" />
      <list-item-stat
        v-if="showDescendantGroupsCount"
        :tooltip-text="$options.i18n.subgroups"
        icon-name="subgroup"
        :stat="descendantGroupsCount"
        data-testid="subgroups-count"
      />
      <list-item-stat
        v-if="showProjectsCount"
        :tooltip-text="$options.i18n.projects"
        icon-name="project"
        :stat="projectsCount"
        data-testid="projects-count"
      />
      <list-item-stat
        v-if="showGroupMembersCount"
        :tooltip-text="$options.i18n.directMembers"
        icon-name="users"
        :stat="groupMembersCount"
        data-testid="members-count"
      />
    </template>

    <template v-if="hasActions" #actions>
      <group-list-item-actions
        :group="group"
        @refetch="refetch"
        @delete="onActionDelete"
        @leave="onActionLeave"
      />
    </template>

    <template v-if="hasFooterAction" #footer>
      <template v-if="hasActionDelete">
        <group-list-item-prevent-delete-modal
          v-if="group.isLinkedToSubscription"
          :visible="isDeleteModalVisible"
          :modal-id="modalId"
          @change="onDeleteModalChange"
        />
        <group-list-item-delete-modal
          v-else
          :visible="isDeleteModalVisible"
          :modal-id="modalId"
          :phrase="group.fullName"
          :confirm-loading="isDeleteModalLoading"
          :group="group"
          @confirm.prevent="onDeleteModalConfirm"
          @change="onDeleteModalChange"
        />
      </template>

      <template v-if="hasActionLeave">
        <group-list-item-leave-modal
          v-model="isLeaveModalVisible"
          :modal-id="modalId"
          :group="group"
          @success="refetch"
        />
      </template>
    </template>

    <template #children>
      <slot name="children"></slot>
    </template>
  </list-item>
</template>
