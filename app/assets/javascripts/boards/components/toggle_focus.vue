<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { hide } from '~/tooltips';

export default {
  components: {
    GlIcon,
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
  <div class="board-extra-actions">
    <a
      ref="toggleFocusModeButton"
      href="#"
      class="btn btn-default has-tooltip gl-ml-3 js-focus-mode-btn"
      data-qa-selector="focus_mode_button"
      role="button"
      :aria-label="$options.i18n.toggleFocusMode"
      :title="$options.i18n.toggleFocusMode"
      @click="toggleFocusMode"
    >
      <gl-icon :name="isFullscreen ? 'minimize' : 'maximize'" />
    </a>
  </div>
</template>
