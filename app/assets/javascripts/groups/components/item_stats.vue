<script>
import { GlBadge } from '@gitlab/ui';
import isProjectPendingRemoval from 'ee_else_ce/groups/mixins/is_project_pending_removal';
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  ITEM_TYPE,
  VISIBILITY_TYPE_ICON,
  GROUP_VISIBILITY_TYPE,
  PROJECT_VISIBILITY_TYPE,
} from '../constants';
import itemStatsValue from './item_stats_value.vue';

export default {
  components: {
    timeAgoTooltip,
    itemStatsValue,
    GlBadge,
  },
  mixins: [isProjectPendingRemoval],
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.item.visibility];
    },
    visibilityTooltip() {
      if (this.item.type === ITEM_TYPE.GROUP) {
        return GROUP_VISIBILITY_TYPE[this.item.visibility];
      }
      return PROJECT_VISIBILITY_TYPE[this.item.visibility];
    },
    isProject() {
      return this.item.type === ITEM_TYPE.PROJECT;
    },
    isGroup() {
      return this.item.type === ITEM_TYPE.GROUP;
    },
  },
};
</script>

<template>
  <div class="stats gl-text-gray-500">
    <item-stats-value
      v-if="isGroup"
      :title="__('Subgroups')"
      :value="item.subgroupCount"
      css-class="number-subgroups gl-ml-5"
      icon-name="folder-o"
    />
    <item-stats-value
      v-if="isGroup"
      :title="__('Projects')"
      :value="item.projectCount"
      css-class="number-projects gl-ml-5"
      icon-name="bookmark"
    />
    <item-stats-value
      v-if="isGroup"
      :title="__('Members')"
      :value="item.memberCount"
      css-class="number-users gl-ml-5"
      icon-name="users"
    />
    <item-stats-value
      v-if="isProject"
      :value="item.starCount"
      css-class="project-stars"
      icon-name="star"
    />
    <div v-if="isProjectPendingRemoval">
      <gl-badge variant="warning">{{ __('pending deletion') }}</gl-badge>
    </div>
    <div v-if="isProject" class="last-updated">
      <time-ago-tooltip :time="item.updatedAt" tooltip-placement="bottom" />
    </div>
  </div>
</template>
