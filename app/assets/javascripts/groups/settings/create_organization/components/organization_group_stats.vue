<script>
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';

export default {
  name: 'OrganizationGroupStats',
  components: {
    ListItemStat,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  methods: {
    numberToMetricPrefix,
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-x-3">
    <list-item-stat
      :tooltip-text="__('Subgroups')"
      icon-name="subgroup"
      :stat="numberToMetricPrefix(group.descendantGroupsCount)"
    />
    <list-item-stat
      :tooltip-text="__('Projects')"
      icon-name="project"
      :stat="numberToMetricPrefix(group.projectsCount)"
    />
    <list-item-stat
      :tooltip-text="__('Direct members')"
      icon-name="users"
      :stat="numberToMetricPrefix(group.groupMembersCount)"
    />
  </div>
</template>
