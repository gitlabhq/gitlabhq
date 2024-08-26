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
  data() {
    return {
      isFullscreen: false,
    };
  },
  methods: {
    toggleFocusMode() {
      hide(this.$refs.toggleFocusModeButton);

      const issueBoardsContent = document.querySelector('.content-wrapper > .js-focus-mode-board');
      issueBoardsContent?.classList.toggle('is-focused');

      this.isFullscreen = !this.isFullscreen;
    },
  },
  i18n: {
    toggleFocusMode: __('Toggle focus mode'),
  },
};
</script>

<template>
  <div class="gl-hidden gl-items-center md:gl-flex">
    <gl-button
      ref="toggleFocusModeButton"
      v-gl-tooltip
      category="tertiary"
      :icon="isFullscreen ? 'minimize' : 'maximize'"
      data-testid="focus-mode-button"
      :title="$options.i18n.toggleFocusMode"
      :aria-label="$options.i18n.toggleFocusMode"
      @click="toggleFocusMode"
    />
  </div>
</template>
