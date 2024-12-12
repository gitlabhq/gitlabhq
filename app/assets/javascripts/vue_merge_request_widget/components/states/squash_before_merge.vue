<script>
import { GlTooltipDirective, GlFormCheckbox, GlLink } from '@gitlab/ui';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { SQUASH_BEFORE_MERGE } from '../../i18n';

export default {
  components: {
    GlFormCheckbox,
    GlLink,
    HelpIcon,
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
      <help-icon :aria-label="$options.i18n.helpLabel" />
    </gl-link>
  </div>
</template>
