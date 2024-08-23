<script>
import { GlFormGroup, GlFormInput, GlLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlFormInput,
    GlLink,
    GlFormGroup,
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
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    suggestedColors: {
      type: Array,
      required: false,
      default: () => [],
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    selectedColor: {
      get() {
        return this.value;
      },
      set(color) {
        this.handleColorClick(color);
      },
    },
    validColor() {
      return !this.errorMessage;
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
  <div>
    <div
      class="suggested-colors gl-grid gl-grid-cols-[repeat(auto-fill,2rem)] gl-justify-between gl-gap-2"
    >
      <gl-link
        v-for="(color, index) in suggestedColors"
        :key="index"
        v-gl-tooltip:tooltipcontainer
        class="gl-block gl-h-7 gl-w-7 gl-rounded-base"
        :style="getStyle(color)"
        :title="getColorName(color)"
        @click.prevent="handleColorClick(getColorCode(color))"
      />
    </div>
    <div class="gl-flex">
      <gl-form-group class="gl-mb-0">
        <gl-form-input
          v-model.trim="selectedColor"
          class="-gl-mr-1 gl-w-8 gl-rounded-e-none"
          type="color"
          :value="selectedColor"
          :placeholder="__('Select color')"
          data-testid="selected-color"
        />
      </gl-form-group>
      <gl-form-group :invalid-feedback="errorMessage" :state="validColor" class="gl-mb-0 gl-grow">
        <gl-form-input
          v-model.trim="selectedColor"
          class="gl-mb-2 gl-rounded-s-none"
          :placeholder="__('Use custom color #FF0000')"
          :autofocus="autofocus"
          :state="validColor"
        />
      </gl-form-group>
    </div>
  </div>
</template>
