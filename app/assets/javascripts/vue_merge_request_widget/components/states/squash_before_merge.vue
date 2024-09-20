<script>
import { GlIcon, GlTooltipDirective, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { SQUASH_BEFORE_MERGE } from '../../i18n';

export default {
  components: {
    GlIcon,
    GlFormCheckbox,
    GlLink,
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
  <div class="gl-flex">
    <gl-form-checkbox
      v-gl-tooltip
      :checked="value"
      :disabled="isDisabled"
      name="squash"
      class="js-squash-checkbox gl-mr-2"
      data-testid="squash-checkbox"
      :title="tooltipTitle"
      @change="(checked) => $emit('input', checked)"
    >
      {{ $options.i18n.checkboxLabel }}
    </gl-form-checkbox>
    <gl-link
      v-if="helpPath"
      v-gl-tooltip
      :href="helpPath"
      :title="$options.i18n.helpLabel"
      class="gl-leading-1"
      target="_blank"
    >
      <gl-icon name="question-o" />
      <span class="sr-only">
        {{ $options.i18n.helpLabel }}
      </span>
    </gl-link>
  </div>
</template>
