<script>
import { GlButtonGroup, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  components: {
    GlButtonGroup,
    GlButton,
    ModalCopyButton,
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
  },
  data() {
    return {
      isMasked: true,
    };
  },
  computed: {
    maskLabel() {
      if (this.isMasked) {
        return __('Click to reveal');
      }
      return __('Click to hide');
    },
    maskIcon() {
      if (this.isMasked) {
        return 'eye';
      }
      return 'eye-slash';
    },
    displayedValue() {
      if (this.isMasked && this.value?.length) {
        return '*'.repeat(this.value.length);
      }
      return this.value;
    },
  },
  methods: {
    onToggleMasked() {
      this.isMasked = !this.isMasked;
    },
    onCopied() {
      // value already in the clipboard, simply notify the user
      this.$toast?.show(s__('Runners|Registration token copied!'));
    },
  },
  i18n: {
    copyLabel: s__('Runners|Copy registration token'),
  },
};
</script>
<template>
  <gl-button-group>
    <gl-button class="gl-font-monospace" data-testid="token-value" label>
      {{ displayedValue }}
    </gl-button>
    <gl-button
      v-gl-tooltip
      :aria-label="maskLabel"
      :title="maskLabel"
      :icon="maskIcon"
      class="gl-w-auto! gl-flex-shrink-0!"
      data-testid="toggle-masked"
      @click.stop="onToggleMasked"
    />
    <modal-copy-button
      class="gl-w-auto! gl-flex-shrink-0!"
      :aria-label="$options.i18n.copyLabel"
      :title="$options.i18n.copyLabel"
      :text="value"
      @success="onCopied"
    />
  </gl-button-group>
</template>
