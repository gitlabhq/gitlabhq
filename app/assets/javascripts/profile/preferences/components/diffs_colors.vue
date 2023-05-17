<script>
import { hexToRgba } from '@gitlab/ui/dist/utils/utils';

import { s__ } from '~/locale';
import { getCssVariable } from '~/lib/utils/css_utils';
import { validateHexColor } from '~/lib/utils/color_utils';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';
import DiffsColorsPreview from './diffs_colors_preview.vue';

export default {
  components: {
    ColorPicker,
    DiffsColorsPreview,
  },
  inject: ['deletion', 'addition'],
  data() {
    return {
      deletionColor: this.deletion || '',
      additionColor: this.addition || '',
      defaultDeletionColor: getCssVariable('--default-diff-color-deletion'),
      defaultAdditionColor: getCssVariable('--default-diff-color-addition'),
    };
  },
  computed: {
    suggestedColors() {
      const colors = {
        '#d99530': s__('SuggestedColors|Orange'),
        '#1f75cb': s__('SuggestedColors|Blue'),
      };
      if (this.isValidColor(this.deletion)) {
        colors[this.deletion] = s__('SuggestedColors|Current removal color');
      }
      if (this.isValidColor(this.addition)) {
        colors[this.addition] = s__('SuggestedColors|Current addition color');
      }
      if (this.isValidColor(this.defaultDeletionColor)) {
        colors[this.defaultDeletionColor] = s__('SuggestedColors|Default removal color');
      }
      if (this.isValidColor(this.defaultAdditionColor)) {
        colors[this.defaultAdditionColor] = s__('SuggestedColors|Default addition color');
      }
      return colors;
    },
    previewClasses() {
      return {
        'diff-custom-addition-color': this.isValidColor(this.additionColor),
        'diff-custom-deletion-color': this.isValidColor(this.deletionColor),
      };
    },
    previewStyle() {
      let style = {};
      if (this.isValidColor(this.deletionColor)) {
        style = {
          ...style,
          '--diff-deletion-color': hexToRgba(this.deletionColor, 0.2),
        };
      }
      if (this.isValidColor(this.additionColor)) {
        style = {
          ...style,
          '--diff-addition-color': hexToRgba(this.additionColor, 0.2),
        };
      }
      return style;
    },
  },
  methods: {
    isValidColor(color) {
      return validateHexColor(color);
    },
  },
  i18n: {
    colorDeletionInputLabel: s__('Preferences|Color for removed lines'),
    colorAdditionInputLabel: s__('Preferences|Color for added lines'),
    previewLabel: s__('Preferences|Preview'),
  },
};
</script>
<template>
  <div :style="previewStyle" :class="previewClasses">
    <diffs-colors-preview />
    <color-picker
      v-model="deletionColor"
      :label="$options.i18n.colorDeletionInputLabel"
      :state="isValidColor(deletionColor)"
      :suggested-colors="suggestedColors"
    />
    <input
      id="user_diffs_deletion_color"
      v-model="deletionColor"
      name="user[diffs_deletion_color]"
      type="hidden"
    />
    <color-picker
      v-model="additionColor"
      :label="$options.i18n.colorAdditionInputLabel"
      :state="isValidColor(additionColor)"
      :suggested-colors="suggestedColors"
    />
    <input
      id="user_diffs_addition_color"
      v-model="additionColor"
      name="user[diffs_addition_color]"
      type="hidden"
    />
  </div>
</template>
