<script>
import { GlIcon, GlTooltipDirective, GlFormCheckbox } from '@gitlab/ui';
import { SQUASH_BEFORE_MERGE } from '../../i18n';

export default {
  components: {
    GlIcon,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    ...SQUASH_BEFORE_MERGE,
  },
  props: {
    value: {
      type: Boolean,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    isDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tooltipTitle() {
      return this.isDisabled ? this.$options.i18n.tooltipTitle : null;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-form-checkbox
      v-gl-tooltip
      :checked="value"
      :disabled="isDisabled"
      name="squash"
      class="js-squash-checkbox gl-mr-2 gl-display-flex gl-align-items-center"
      data-qa-selector="squash_checkbox"
      :title="tooltipTitle"
      @change="(checked) => $emit('input', checked)"
    >
      {{ $options.i18n.checkboxLabel }}
    </gl-form-checkbox>
    <a
      v-if="helpPath"
      v-gl-tooltip
      :href="helpPath"
      :title="$options.i18n.helpLabel"
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      <gl-icon name="question" />
      <span class="sr-only">
        {{ $options.i18n.helpLabel }}
      </span>
    </a>
  </div>
</template>
