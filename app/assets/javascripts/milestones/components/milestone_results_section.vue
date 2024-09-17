<script>
import {
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlDropdownItem,
  GlBadge,
  GlIcon,
} from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'MilestoneResultsSection',
  components: {
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlDropdownItem,
    GlBadge,
    GlIcon,
  },
  props: {
    sectionTitle: {
      type: String,
      required: true,
    },
    totalCount: {
      type: Number,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    selectedMilestones: {
      type: Array,
      required: true,
      default: () => [],
    },
    error: {
      type: Error,
      required: false,
      default: null,
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    totalCountText() {
      return this.totalCount > 999 ? s__('TotalMilestonesIndicator|1000+') : `${this.totalCount}`;
    },
  },
  methods: {
    isSelectedMilestone(item) {
      return this.selectedMilestones.includes(item);
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-section-header>
      <div class="gl-flex gl-items-center gl-pl-6" data-testid="milestone-results-section-header">
        <span class="gl-mb-1 gl-mr-2">{{ sectionTitle }}</span>
        <gl-badge variant="neutral">{{ totalCountText }}</gl-badge>
      </div>
    </gl-dropdown-section-header>
    <template v-if="error">
      <div class="align-items-start gl-mb-3 gl-ml-4 gl-mr-4 gl-flex gl-text-red-500">
        <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-shrink-0" />
        <span>{{ errorMessage }}</span>
      </div>
    </template>
    <template v-else>
      <gl-dropdown-item
        v-for="{ title } in items"
        :key="title"
        :is-checked="isSelectedMilestone(title)"
        is-check-item
        @click="$emit('selected', title)"
      >
        {{ title }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
    </template>
  </div>
</template>
