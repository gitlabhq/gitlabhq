<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { s__ } from '~/locale';
import OrganizationGroupStats from './organization_group_stats.vue';

export default {
  name: 'OrganizationGroupCard',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    OrganizationGroupStats,
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
            "Organization|This group will become private to match the Organization's visibility.",
          );

        case VISIBILITY_LEVEL_INTERNAL_STRING:
          return s__(
            "Organization|This group will become internal to match the Organization's visibility.",
          );

        default:
          return '';
      }
    },
  },
};
</script>

<template>
  <div class="gl-rounded-xl gl-bg-default gl-p-4" data-testid="organization-group">
    <div class="gl-flex gl-items-start gl-justify-between">
      <span class="gl-font-bold gl-break-anywhere">{{ group.fullName }}</span>
      <div class="gl-flex gl-items-center gl-gap-2">
        <gl-icon
          v-gl-tooltip="visibilityTooltip"
          :name="visibilityIcon"
          variant="subtle"
          data-testid="group-visibility"
        />
        <gl-icon
          v-if="hasVisibilityChanged"
          v-gl-tooltip="visibilityChangedTooltip"
          name="warning-solid"
          variant="warning"
          data-testid="visibility-warning"
        />
      </div>
    </div>
    <organization-group-stats class="gl-mt-3" :group="group" />
  </div>
</template>
