<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { hide } from '~/tooltips';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      isFullscreen: false,
    };
  },
  methods: {
    toggleFocusMode() {
      hide(this.$refs.toggleFocusModeButton);

      const boardWrapperElSelector = this.glFeatures.projectStudioEnabled
        ? '.js-content-panels'
        : '.content-wrapper > .js-focus-mode-board';
      const issueBoardsContent = document.querySelector(boardWrapperElSelector);
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
  <div class="gl-hidden gl-items-center @md/panel:gl-flex">
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
