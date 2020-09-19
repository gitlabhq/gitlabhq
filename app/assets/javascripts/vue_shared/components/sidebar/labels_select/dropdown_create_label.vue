<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    headerTitle: {
      type: String,
      required: false,
      default: () => __('Create new label'),
    },
  },
  created() {
    const rawLabelsColors = gon.suggested_label_colors;
    this.suggestedColors = Object.keys(rawLabelsColors).map(colorCode => ({
      colorCode,
      title: rawLabelsColors[colorCode],
    }));
  },
};
</script>

<template>
  <div class="dropdown-page-two dropdown-new-label">
    <div
      class="dropdown-title gl-display-flex gl-justify-content-space-between gl-align-items-center"
    >
      <gl-button
        :aria-label="__('Go back')"
        category="tertiary"
        class="dropdown-menu-back"
        icon="arrow-left"
        size="small"
      />
      {{ headerTitle }}
      <gl-button
        :aria-label="__('Close')"
        category="tertiary"
        class="dropdown-menu-close"
        icon="close"
        size="small"
      />
    </div>
    <div class="dropdown-content">
      <div class="dropdown-labels-error js-label-error"></div>
      <input
        id="new_label_name"
        :placeholder="__('Name new label')"
        type="text"
        class="default-dropdown-input"
      />
      <div class="suggest-colors suggest-colors-dropdown">
        <a
          v-for="(color, index) in suggestedColors"
          :key="index"
          v-gl-tooltip
          :data-color="color.colorCode"
          :style="{
            backgroundColor: color.colorCode,
          }"
          :title="color.title"
          href="#"
        >
          &nbsp;
        </a>
      </div>
      <div class="dropdown-label-color-input">
        <div class="dropdown-label-color-preview js-dropdown-label-color-preview"></div>
        <input
          id="new_label_color"
          :placeholder="__('Assign custom color like #FF0000')"
          type="text"
          class="default-dropdown-input"
        />
      </div>
      <div class="clearfix">
        <gl-button category="secondary" class="float-left js-new-label-btn disabled">
          {{ __('Create') }}
        </gl-button>
        <gl-button category="secondary" class="float-right js-cancel-label-btn">
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
