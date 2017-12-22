<script>
import icon from '~/vue_shared/components/icon.vue';
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ITEM_TYPE, VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE, PROJECT_VISIBILITY_TYPE } from '../constants';
import itemStatsValue from './item_stats_value.vue';

export default {
  components: {
    icon,
    timeAgoTooltip,
    itemStatsValue,
  },
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
  <div class="stats">
    <item-stats-value
      v-if="isGroup"
      css-class="number-subgroups"
      icon-name="folder"
      :title="s__('Subgroups')"
      :value=item.subgroupCount
    />
    <item-stats-value
      v-if="isGroup"
      css-class="number-projects"
      icon-name="bookmark"
      :title="s__('Projects')"
      :value=item.projectCount
    />
    <item-stats-value
      v-if="isGroup"
      css-class="number-users"
      icon-name="users"
      :title="s__('Members')"
      :value=item.memberCount
    />
    <span
      v-if="isProject"
      class="project-stars">
      <icon name="star"/>
      <span class="stat-value">{{item.starCount}}</span>
    </span>
    <item-stats-value
      css-class="item-visibility"
      tooltip-placement="left"
      :icon-name="visibilityIcon"
      :title="visibilityTooltip"
    />
    <div
      class="last-updated"
      v-if="isProject"
    >
      <time-ago-tooltip
        tooltip-placement="bottom"
        :time="item.updatedAt"
      />
    </div>
  </div>
</template>
