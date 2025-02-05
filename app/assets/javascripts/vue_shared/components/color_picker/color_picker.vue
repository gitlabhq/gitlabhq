<script>
/**
 * Renders a color picker input with preset colors to choose from
 *
 * @example
 * <color-picker
     :id="example-id"
     :invalid-feedback="__('Please enter a valid hex (#RRGGBB or #RGB) color value')"
     :label="__('Background color')"
     :value="#FF0000"
     :suggestedColors="{ '#ff0000': 'Red', '#808080': 'Gray' }",
     state="isValidColor"
   />
 */
import { GlFormGroup, GlFormInput, GlFormInputGroup, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';

const PREVIEW_COLOR_DEFAULT_CLASSES =
  'gl-relative gl-w-7 gl-bg-subtle gl-rounded-tl-base gl-rounded-bl-base';

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
    id: {
      type: String,
      required: false,
      default: () => uniqueId('color-picker-'),
    },
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
    suggestedColors: {
      type: Object,
      required: false,
      default: () => gon.suggested_label_colors,
    },
  },
  computed: {
    description() {
      return this.hasSuggestedColors
        ? this.$options.i18n.fullDescription
        : this.$options.i18n.shortDescription;
    },
    previewColor() {
      if (this.state) {
        return { backgroundColor: this.value };
      }

      return {};
    },
    previewColorClasses() {
      const borderStyle =
        this.state === false ? 'gl-shadow-inner-1-red-500' : 'gl-shadow-inner-1-gray-400';

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
    fullDescription: __('Enter any color or choose one of the suggested colors below.'),
    shortDescription: __('Enter any color.'),
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="label"
      :label-for="id"
      :description="description"
      :invalid-feedback="invalidFeedback"
      :state="state"
      :class="{ '!gl-mb-3': hasSuggestedColors }"
    >
      <gl-form-input-group
        max-length="7"
        type="text"
        class="gl-align-center gl-max-w-26 gl-rounded-none gl-rounded-br-base gl-rounded-tr-base"
        :value="value"
        :state="state"
        :aria-labelledby="label"
        @input="handleColorChange"
      >
        <template #prepend>
          <div :class="previewColorClasses" :style="previewColor" data-testid="color-preview">
            <gl-form-input
              :id="id"
              type="color"
              class="gl-absolute gl-left-0 gl-top-0 !gl-m-0 !gl-h-full !gl-p-0 gl-opacity-0"
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
        class="gl-mb-3 gl-mr-3 gl-inline-block gl-h-7 gl-w-7 gl-rounded-base gl-no-underline"
        @click.prevent="handleColorChange(hex)"
      />
    </div>
  </div>
</template>
