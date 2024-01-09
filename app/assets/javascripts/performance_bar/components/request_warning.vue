<script>
import { GlTooltipDirective } from '@gitlab/ui';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    htmlId: {
      type: String,
      required: true,
    },
    warnings: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasWarnings() {
      return this.warnings && this.warnings.length;
    },
    warningMessage() {
      if (!this.hasWarnings) {
        return '';
      }

      return this.warnings.join('\n');
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>
<template>
  <span v-if="hasWarnings" class="gl-cursor-default">
    <gl-emoji
      v-if="hasWarnings"
      :id="htmlId"
      v-gl-tooltip.viewport="warningMessage"
      data-name="warning"
      data-testid="warning"
      class="gl-ml-2"
    />
  </span>
</template>
