<script>
import { GlFormInput, GlLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlFormInput,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    suggestedColors() {
      const colorsMap = gon.suggested_label_colors;
      return Object.keys(colorsMap).map((color) => ({ [color]: colorsMap[color] }));
    },
    selectedColor: {
      get() {
        return this.value;
      },
      set(color) {
        this.handleColorClick(color);
      },
    },
  },
  methods: {
    handleColorClick(color) {
      this.$emit('input', color);
    },
    getColorCode(color) {
      return Object.keys(color).pop();
    },
    getColorName(color) {
      return Object.values(color).pop();
    },
    getStyle(color) {
      return {
        backgroundColor: this.getColorCode(color),
      };
    },
  },
};
</script>
<template>
  <div class="dropdown-content">
    <div class="suggest-colors suggest-colors-dropdown gl-mt-0!">
      <gl-link
        v-for="(color, index) in suggestedColors"
        :key="index"
        v-gl-tooltip:tooltipcontainer
        :style="getStyle(color)"
        :title="getColorName(color)"
        @click.prevent="handleColorClick(getColorCode(color))"
      />
    </div>
    <div class="color-input-container gl-display-flex">
      <gl-form-input
        v-model.trim="selectedColor"
        class="gl-rounded-top-right-none gl-rounded-bottom-right-none gl-mr-n1 gl-mb-2 gl-w-8"
        type="color"
        :value="selectedColor"
        :placeholder="__('Select color')"
        data-testid="selected-color"
      />
      <gl-form-input
        v-model.trim="selectedColor"
        :autofocus="autofocus"
        class="gl-rounded-top-left-none gl-rounded-bottom-left-none gl-mb-2"
        :placeholder="__('Use custom color #FF0000')"
        data-testid="selected-color-text"
      />
    </div>
  </div>
</template>
