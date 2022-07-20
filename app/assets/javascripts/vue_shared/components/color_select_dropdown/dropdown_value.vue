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
  computed: {
    hasColor() {
      return this.selectedColor.color !== '';
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
      <color-item :color="selectedColor.color" :title="selectedColor.title" />
    </div>

    <span v-if="!hasColor" class="no-value hide-collapsed">
      <slot></slot>
    </span>
    <template v-else>
      <color-item
        class="hide-collapsed"
        :color="selectedColor.color"
        :title="selectedColor.title"
      />
    </template>
  </div>
</template>
