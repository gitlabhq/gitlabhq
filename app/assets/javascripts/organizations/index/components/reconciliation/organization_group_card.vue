<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';

export default {
  name: 'OrganizationGroupCard',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
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
    visibilityIcon(visibility) {
      return VISIBILITY_TYPE_ICON[visibility];
    },
    visibilityTooltip(visibility) {
      return GROUP_VISIBILITY_TYPE[visibility];
    },
  },
};
</script>

<template>
  <div class="gl-rounded-xl gl-bg-default gl-p-4" data-testid="organization-group">
    <div class="gl-flex gl-items-center gl-gap-3">
      <gl-icon class="gl-shrink-0" variant="subtle" name="group" />
      <div class="gl-break-anywhere">
        <span class="gl-font-bold">{{ group.fullName }}</span
        ><gl-icon
          v-gl-tooltip="visibilityTooltip(group.visibility)"
          :name="visibilityIcon(group.visibility)"
          class="gl-ml-2"
          variant="subtle"
          data-testid="group-visibility"
        />
      </div>
    </div>
    <div class="gl-mt-3 gl-flex gl-items-center gl-gap-x-3 gl-pl-6">
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
  </div>
</template>
