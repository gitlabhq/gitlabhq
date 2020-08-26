<script>
import { GlTooltip, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { uniqueId } from 'lodash';

const getTooltipTitle = element => {
  return element.getAttribute('title') || element.dataset.title;
};

const newTooltip = (element, config = {}) => {
  const { placement, container, boundary, html, triggers } = element.dataset;
  const title = getTooltipTitle(element);

  return {
    id: uniqueId('gl-tooltip'),
    target: element,
    title,
    html,
    placement,
    container,
    boundary,
    triggers,
    disabled: !title,
    ...config,
  };
};

export default {
  components: {
    GlTooltip,
  },
  directives: {
    SafeHtml,
  },
  data() {
    return {
      tooltips: [],
    };
  },
  methods: {
    addTooltips(elements, config) {
      const newTooltips = elements
        .filter(element => !this.tooltipExists(element))
        .map(element => newTooltip(element, config));

      this.tooltips.push(...newTooltips);
    },
    tooltipExists(element) {
      return this.tooltips.some(tooltip => tooltip.target === element);
    },
  },
};
</script>
<template>
  <div>
    <gl-tooltip
      v-for="(tooltip, index) in tooltips"
      :id="tooltip.id"
      :key="index"
      :target="tooltip.target"
      :triggers="tooltip.triggers"
      :placement="tooltip.placement"
      :container="tooltip.container"
      :boundary="tooltip.boundary"
      :disabled="tooltip.disabled"
    >
      <span v-if="tooltip.html" v-safe-html="tooltip.title"></span>
      <span v-else>{{ tooltip.title }}</span>
    </gl-tooltip>
  </div>
</template>
