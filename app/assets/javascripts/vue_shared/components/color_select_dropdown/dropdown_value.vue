<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { COLOR_WIDGET_COLOR } from './constants';
import ColorItem from './color_item.vue';

export default {
  i18n: {
    dropdownTitle: COLOR_WIDGET_COLOR,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    ColorItem,
  },
  props: {
    selectedColor: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="value js-value">
    <div
      v-gl-tooltip.left.viewport
      :title="$options.i18n.dropdownTitle"
      class="sidebar-collapsed-icon"
    >
      <gl-icon name="appearance" />
      <color-item
        :color="selectedColor.color"
        :title="selectedColor.title"
        class="gl-font-base gl-line-height-24"
      />
    </div>

    <color-item class="hide-collapsed" :color="selectedColor.color" :title="selectedColor.title" />
  </div>
</template>
