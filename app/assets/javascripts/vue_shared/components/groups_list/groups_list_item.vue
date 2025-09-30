<script>
import { GlIcon, GlBadge, GlTooltip } from '@gitlab/ui';

import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { __ } from '~/locale';
import { numberToMetricPrefix, numberToHumanSize, isNumeric } from '~/lib/utils/number_utils';
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import ListItemInactiveBadge from '~/vue_shared/components/resource_lists/list_item_inactive_badge.vue';

export default {
  i18n: {
    subgroups: __('Subgroups'),
    projects: __('Projects'),
    directMembers: __('Direct members'),
  },
  components: {
    ListItem,
    ListItemStat,
    GlIcon,
    GlBadge,
    GlTooltip,
    GroupListItemActions,
    ListItemInactiveBadge,
    GroupsListItemPlanBadge: () =>
      import('ee_component/vue_shared/components/groups_list/groups_list_item_plan_badge.vue'),
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
    includeMicrodata: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    visibilityTooltipTarget() {
      return this.$refs?.visibilityIcon?.$el;
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
    microdataAttributes() {
      if (!this.includeMicrodata) return {};

      return {
        itemprop: 'subOrganization',
        itemtype: 'https://schema.org/Organization',
        itemscope: true,
        avatarAttrs: { itemprop: 'logo', labelLinkAttrs: { itemprop: 'name' } },
        descriptionAttrs: { itemprop: 'description' },
      };
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

      return numberToHumanSize(this.group.projectStatistics?.storageSize || 0);
    },
    hasStorageSize() {
      return Object.hasOwn(this.group, 'projectStatistics');
    },
    hasActions() {
      return this.group.availableActions?.length;
    },
    dataTestid() {
      return `groups-list-item-${this.group.id}`;
    },
  },
  methods: {
    refetch() {
      this.$emit('refetch');
    },
    onVisibilityTooltipShown() {
      this.$emit('hover-visibility', this.visibility);
    },
  },
};
</script>

<template>
  <list-item
    v-bind="microdataAttributes"
    :resource="group"
    :show-icon="showGroupIcon"
    :icon-name="groupIconName"
    :list-item-class="listItemClass"
    :timestamp-type="timestampType"
    :data-testid="dataTestid"
    @click-avatar="$emit('click-avatar')"
  >
    <template #children-toggle>
      <slot name="children-toggle"></slot>
    </template>
    <template #avatar-meta>
      <template v-if="visibility">
        <gl-icon ref="visibilityIcon" :name="visibilityIcon" variant="subtle" />
        <gl-tooltip :target="() => visibilityTooltipTarget" @shown="onVisibilityTooltipShown">{{
          visibilityTooltip
        }}</gl-tooltip>
      </template>
      <gl-badge v-if="shouldShowAccessLevel" class="gl-block" data-testid="user-access-role">{{
        accessLevelLabel
      }}</gl-badge>
    </template>

    <template #stats>
      <list-item-inactive-badge :resource="group" />
      <gl-badge v-if="hasStorageSize" data-testid="storage-size">{{ storageSize }}</gl-badge>
      <groups-list-item-plan-badge :group="group" />
      <list-item-stat
        v-if="showDescendantGroupsCount"
        :tooltip-text="$options.i18n.subgroups"
        icon-name="subgroup"
        :stat="descendantGroupsCount"
        data-testid="subgroups-count"
        @hover="$emit('hover-stat', 'subgroups-count')"
      />
      <list-item-stat
        v-if="showProjectsCount"
        :tooltip-text="$options.i18n.projects"
        icon-name="project"
        :stat="projectsCount"
        data-testid="projects-count"
        @hover="$emit('hover-stat', 'projects-count')"
      />
      <list-item-stat
        v-if="showGroupMembersCount"
        :tooltip-text="$options.i18n.directMembers"
        icon-name="users"
        :stat="groupMembersCount"
        data-testid="members-count"
        @hover="$emit('hover-stat', 'members-count')"
      />
    </template>

    <template v-if="hasActions" #actions>
      <group-list-item-actions :group="group" @refetch="refetch" />
    </template>

    <template #children>
      <slot name="children"></slot>
    </template>
  </list-item>
</template>
