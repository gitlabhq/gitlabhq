<script>
import { GlTooltipDirective, GlFormCheckbox, GlLink } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { SQUASH_BEFORE_MERGE } from '../../i18n';

export default {
  components: {
    GlFormCheckbox,
    GlLink,
    HelpPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
    popoverOptions() {
      return this.$options.i18n.popoverOptions;
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
    <help-popover
      v-if="helpPath"
      class="gl-flex gl-items-start"
      :options="popoverOptions"
      :aria-label="$options.i18n.helpLabel"
    >
      <template v-if="popoverOptions.content">
        <p
          v-if="popoverOptions.content.text"
          v-safe-html="popoverOptions.content.text"
          class="gl-mb-0"
        ></p>
        <gl-link
          v-if="popoverOptions.content.learnMorePath"
          :href="popoverOptions.content.learnMorePath"
          target="_blank"
          class="gl-text-sm"
          >{{ $options.i18n.learnMore }}</gl-link
        >
      </template>
    </help-popover>
  </div>
</template>
