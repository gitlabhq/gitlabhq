<script>
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { ITEM_TYPE } from '../constants';
import ItemStatsValue from './item_stats_value.vue';

export default {
  components: {
    TimeAgoTooltip,
    ItemStatsValue,
  },
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
    subgroupCount() {
      return this.numberToMetricPrefixWithFallback(this.item.subgroupCount);
    },
    projectCount() {
      return this.numberToMetricPrefixWithFallback(this.item.projectCount);
    },
    starCount() {
      return this.numberToMetricPrefixWithFallback(this.item.starCount);
    },
  },
  methods: {
    displayValue(value) {
      return this.isGroup && value !== undefined;
    },
    numberToMetricPrefixWithFallback(number) {
      if (typeof number === 'undefined') {
        return '0';
      }

      try {
        return numberToMetricPrefix(number);
      } catch (e) {
        return '0';
      }
    },
  },
};
</script>

<template>
  <div class="stats gl-text-subtle">
    <item-stats-value
      v-if="displayValue(item.subgroupCount)"
      :title="__('Subgroups')"
      :value="subgroupCount"
      css-class="number-subgroups gl-ml-5"
      icon-name="subgroup"
      data-testid="subgroup-count"
    />
    <item-stats-value
      v-if="displayValue(item.projectCount)"
      :title="__('Projects')"
      :value="projectCount"
      css-class="number-projects gl-ml-5"
      icon-name="project"
      data-testid="project-count"
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
      :value="starCount"
      css-class="project-stars"
      data-testid="star-count"
      icon-name="star"
    />
    <div v-if="isProject" class="last-updated gl-text-sm">
      <time-ago-tooltip :time="item.lastActivityAt" tooltip-placement="bottom" />
    </div>
  </div>
</template>
