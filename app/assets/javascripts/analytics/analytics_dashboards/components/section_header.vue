<script>
import { uniqueId } from 'lodash-es';
import { GlIcon, GlPopover } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'SectionHeader',
  components: {
    GlIcon,
    GlPopover,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    tooltip: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    // A dashboard can render several sections, so the popover target must be unique.
    return { tooltipId: uniqueId('section-header-tooltip-') };
  },
  computed: {
    hasTooltip() {
      return Boolean(this.tooltip.description);
    },
    // GlIcon is aria-hidden unless it has a label, so a focusable icon without one
    // announces nothing. Name it after its section, since a dashboard can render
    // several and "More information" alone does not say which.
    tooltipLabel() {
      return sprintf(s__('AnalyticsDashboards|More information about %{title}'), {
        title: this.title,
      });
    },
  },
};
</script>

<template>
  <!-- gl-h-full fills the grid cell and gl-mt-auto sinks the rule and text to its bottom edge, so
       the spare rows become spacing from the panel above. Not justify-end: a block taller than the
       cell then overflows downward, where gridstack scrolls it, instead of off the clipped top. -->
  <div class="gl-flex gl-h-full gl-flex-col gl-px-0">
    <div class="gl-border-t gl-mt-auto gl-pt-4" data-testid="section-header-divider">
      <div class="gl-flex gl-items-center gl-gap-2">
        <h3 class="gl-heading-4 gl-m-0" data-testid="section-header-title">{{ title }}</h3>
        <template v-if="hasTooltip">
          <gl-icon
            :id="tooltipId"
            name="information-o"
            class="gl-text-subtle"
            tabindex="0"
            :aria-label="tooltipLabel"
            data-testid="section-header-tooltip-icon"
          />
          <gl-popover :target="tooltipId" :title="tooltip.title">
            {{ tooltip.description }}
          </gl-popover>
        </template>
      </div>
      <p
        v-if="description"
        class="gl-m-0 gl-mt-1 gl-text-sm gl-text-subtle"
        data-testid="section-header-description"
      >
        {{ description }}
      </p>
    </div>
  </div>
</template>
