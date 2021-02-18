<script>
/**
 * Renders a color picker input with preset colors to choose from
 *
 * @example
 * <color-picker
     :invalid-feedback="__('Please enter a valid hex (#RRGGBB or #RGB) color value')"
     :label="__('Background color')"
     :value="#FF0000"
     state="isValidColor"
   />
 */
import { GlFormGroup, GlFormInput, GlFormInputGroup, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

const PREVIEW_COLOR_DEFAULT_CLASSES =
  'gl-relative gl-w-7 gl-bg-gray-10 gl-rounded-top-left-base gl-rounded-bottom-left-base';

export default {
  name: 'ColorPicker',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    invalidFeedback: {
      type: String,
      required: false,
      default: __('Please enter a valid hex (#RRGGBB or #RGB) color value'),
    },
    label: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
    state: {
      type: Boolean,
      required: false,
      default: null,
    },
  },
  computed: {
    description() {
      return this.hasSuggestedColors
        ? this.$options.i18n.fullDescription
        : this.$options.i18n.shortDescription;
    },
    suggestedColors() {
      return gon.suggested_label_colors;
    },
    previewColor() {
      if (this.state) {
        return { backgroundColor: this.value };
      }

      return {};
    },
    previewColorClasses() {
      const borderStyle =
        this.state === false ? 'gl-inset-border-1-red-500' : 'gl-inset-border-1-gray-400';

      return `${PREVIEW_COLOR_DEFAULT_CLASSES} ${borderStyle}`;
    },
    hasSuggestedColors() {
      return Object.keys(this.suggestedColors).length;
    },
  },
  methods: {
    handleColorChange(color) {
      this.$emit('input', color.trim());
    },
  },
  i18n: {
    fullDescription: __('Choose any color. Or you can choose one of the suggested colors below'),
    shortDescription: __('Choose any color'),
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="label"
      label-for="color-picker"
      :description="description"
      :invalid-feedback="invalidFeedback"
      :state="state"
      :class="{ 'gl-mb-3!': hasSuggestedColors }"
    >
      <gl-form-input-group
        id="color-picker"
        max-length="7"
        type="text"
        class="gl-align-center gl-rounded-0 gl-rounded-top-right-base gl-rounded-bottom-right-base"
        :value="value"
        :state="state"
        @input="handleColorChange"
      >
        <template #prepend>
          <div :class="previewColorClasses" :style="previewColor" data-testid="color-preview">
            <gl-form-input
              type="color"
              class="gl-absolute gl-top-0 gl-left-0 gl-h-full! gl-p-0! gl-m-0! gl-cursor-pointer gl-opacity-0"
              tabindex="-1"
              :value="value"
              @input="handleColorChange"
            />
          </div>
        </template>
      </gl-form-input-group>
    </gl-form-group>

    <div v-if="hasSuggestedColors" class="gl-mb-3">
      <gl-link
        v-for="(name, hex) in suggestedColors"
        :key="hex"
        v-gl-tooltip
        :title="name"
        :style="{ backgroundColor: hex }"
        class="gl-rounded-base gl-w-7 gl-h-7 gl-display-inline-block gl-mr-3 gl-mb-3 gl-text-decoration-none"
        @click.prevent="handleColorChange(hex)"
      />
    </div>
  </div>
</template>
