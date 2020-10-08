<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { SQUASH_BEFORE_MERGE } from '../../i18n';

export default {
  components: {
    GlIcon,
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
    tooltipFocusable() {
      return this.isDisabled ? '0' : null;
    },
  },
};
</script>

<template>
  <div class="inline">
    <label
      v-gl-tooltip
      :class="{ 'gl-text-gray-400': isDisabled }"
      :tabindex="tooltipFocusable"
      data-testid="squashLabel"
      :title="tooltipTitle"
    >
      <input
        :checked="value"
        :disabled="isDisabled"
        type="checkbox"
        name="squash"
        class="qa-squash-checkbox js-squash-checkbox"
        @change="$emit('input', $event.target.checked)"
      />
      {{ $options.i18n.checkboxLabel }}
    </label>
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
