<script>
import { GlBadge } from '@gitlab/ui';
import isProjectPendingRemoval from 'ee_else_ce/groups/mixins/is_project_pending_removal';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ITEM_TYPE } from '../constants';
import ItemStatsValue from './item_stats_value.vue';

export default {
  components: {
    TimeAgoTooltip,
    ItemStatsValue,
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
    isProject() {
      return this.item.type === ITEM_TYPE.PROJECT;
    },
    isGroup() {
      return this.item.type === ITEM_TYPE.GROUP;
    },
  },
  methods: {
    displayValue(value) {
      return this.isGroup && value !== undefined;
    },
  },
};
</script>

<template>
  <div class="stats gl-text-gray-500">
    <item-stats-value
      v-if="displayValue(item.subgroupCount)"
      :title="__('Subgroups')"
      :value="item.subgroupCount"
      css-class="number-subgroups gl-ml-5"
      icon-name="subgroup"
      data-testid="subgroups-count"
    />
    <item-stats-value
      v-if="displayValue(item.projectCount)"
      :title="__('Projects')"
      :value="item.projectCount"
      css-class="number-projects gl-ml-5"
      icon-name="project"
      data-testid="projects-count"
    />
    <item-stats-value
      v-if="isGroup"
      :title="__('Direct members')"
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
      <time-ago-tooltip :time="item.lastActivityAt" tooltip-placement="bottom" />
    </div>
  </div>
</template>
