<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { hide } from '~/tooltips';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    issueBoardsContentSelector: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isFullscreen: false,
    };
  },
  methods: {
    toggleFocusMode() {
      hide(this.$refs.toggleFocusModeButton);

      const issueBoardsContent = document.querySelector(this.issueBoardsContentSelector);
      issueBoardsContent.classList.toggle('is-focused');

      this.isFullscreen = !this.isFullscreen;
    },
  },
  i18n: {
    toggleFocusMode: __('Toggle focus mode'),
  },
};
</script>

<template>
  <div class="gl-ml-3 gl-display-none gl-md-display-flex gl-align-items-center">
    <gl-button
      ref="toggleFocusModeButton"
      v-gl-tooltip
      category="tertiary"
      :icon="isFullscreen ? 'minimize' : 'maximize'"
      class="js-focus-mode-btn"
      data-qa-selector="focus_mode_button"
      :title="$options.i18n.toggleFocusMode"
      :aria-label="$options.i18n.toggleFocusMode"
      @click="toggleFocusMode"
    />
  </div>
</template>
