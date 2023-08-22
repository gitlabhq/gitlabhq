<script>
import { GlIcon } from '@gitlab/ui';
import { getSeverity } from '~/ci/reports/utils';

export default {
  components: { GlIcon },

  props: {
    finding: {
      type: Object,
      required: true,
    },
  },
  computed: {
    enhancedFinding() {
      return getSeverity(this.finding);
    },
    listText() {
      return `${this.finding.severity} - ${this.finding.description}`;
    },
  },
};
</script>

<template>
  <li class="gl-py-1 gl-font-regular gl-display-flex">
    <span class="gl-mr-3">
      <gl-icon
        :size="12"
        :name="enhancedFinding.name"
        :class="enhancedFinding.class"
        class="inline-findings-severity-icon"
      />
    </span>
    <span data-testid="description-plain-text" class="gl-display-flex">
      {{ listText }}
    </span>
  </li>
</template>
