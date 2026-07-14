<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
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
    organizationVisibility: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    visibility() {
      if (this.organizationVisibility === null) {
        return this.group.visibility;
      }

      const visibilityInteger = VISIBILITY_LEVELS_STRING_TO_INTEGER[this.group.visibility];
      const organizationVisibilityInteger =
        VISIBILITY_LEVELS_STRING_TO_INTEGER[this.organizationVisibility];

      if (visibilityInteger > organizationVisibilityInteger) {
        return this.organizationVisibility;
      }

      return this.group.visibility;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.visibility];
    },
    hasVisibilityChanged() {
      return this.visibility !== this.group.visibility;
    },
    visibilityChangedTooltip() {
      if (!this.hasVisibilityChanged) {
        return '';
      }

      switch (this.visibility) {
        case VISIBILITY_LEVEL_PRIVATE_STRING:
          return s__(
            'Organization|The visibility of this group will be changed to private because the Organization is private.',
          );

        case VISIBILITY_LEVEL_INTERNAL_STRING:
          return s__(
            'Organization|The visibility of this group will be changed to internal because the Organization is internal.',
          );

        default:
          return '';
      }
    },
  },
  methods: {
    numberToMetricPrefix,
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
          v-gl-tooltip="visibilityTooltip"
          :name="visibilityIcon"
          class="gl-ml-2"
          variant="subtle"
          data-testid="group-visibility"
        /><gl-icon
          v-if="hasVisibilityChanged"
          v-gl-tooltip="visibilityChangedTooltip"
          name="warning-solid"
          class="gl-ml-2"
          variant="warning"
          data-testid="visibility-warning"
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
