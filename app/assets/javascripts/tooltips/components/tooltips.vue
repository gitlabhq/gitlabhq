<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';

const getTooltipTitle = (element) => {
  return element.getAttribute('title') || element.dataset.title;
};

const getTooltipCustomClass = (element) => {
  return element.dataset.tooltipCustomClass;
};

const newTooltip = (element, config = {}) => {
  const { placement, container, boundary, html, triggers } = element.dataset;
  const title = getTooltipTitle(element);
  const customClass = getTooltipCustomClass(element);

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
    customClass,
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
  created() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.removedNodes.forEach(this.dispose);
      });
    });
  },
  beforeDestroy() {
    this.observer.disconnect();
  },
  methods: {
    addTooltips(elements, config) {
      const newTooltips = elements
        .filter((element) => !this.tooltipExists(element))
        .map((element) => newTooltip(element, config))
        .filter((tooltip) => tooltip.title);

      newTooltips.forEach((tooltip) => this.observe(tooltip));

      this.tooltips.push(...newTooltips);
    },
    observe(tooltip) {
      this.observer.observe(tooltip.target.parentElement, {
        childList: true,
      });
    },
    dispose(target) {
      if (!target) {
        this.tooltips = [];
      } else {
        const index = this.tooltips.indexOf(this.findTooltipByTarget(target));

        if (index > -1) {
          this.tooltips.splice(index, 1);
        }
      }
    },
    fixTitle(target) {
      const tooltip = this.findTooltipByTarget(target);

      if (tooltip) {
        tooltip.title = target.getAttribute('title');
      }
    },
    triggerEvent(target, event) {
      const tooltip = this.findTooltipByTarget(target);
      const tooltipRef = this.$refs[tooltip?.id];

      if (tooltipRef) {
        tooltipRef[0].$emit(event);
      }
    },
    tooltipExists(element) {
      return Boolean(this.findTooltipByTarget(element));
    },
    findTooltipByTarget(element) {
      return this.tooltips.find((tooltip) => tooltip.target === element);
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>
<template>
  <div>
    <gl-tooltip
      v-for="(tooltip, index) in tooltips"
      :id="tooltip.id"
      :ref="tooltip.id"
      :key="index"
      :target="tooltip.target"
      :triggers="tooltip.triggers"
      :placement="tooltip.placement"
      :container="tooltip.container"
      :boundary="tooltip.boundary"
      :disabled="tooltip.disabled"
      :show="tooltip.show"
      :custom-class="tooltip.customClass"
      @hidden="$emit('hidden', tooltip)"
    >
      <span v-if="tooltip.html" v-safe-html:[$options.safeHtmlConfig]="tooltip.title"></span>
      <span v-else>{{ tooltip.title }}</span>
    </gl-tooltip>
  </div>
</template>
