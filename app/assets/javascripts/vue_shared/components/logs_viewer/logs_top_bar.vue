<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    isFullScreen: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFollowing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    enterFullScreen: s__('LogsViewer|Enter full screen'),
    exitFullScreen: s__('LogsViewer|Exit full screen'),
    scrollToTop: s__('LogsViewer|Scroll to top'),
    scrollToBottom: s__('LogsViewer|Scroll to bottom'),
  },
  computed: {
    toggleFullScreenIcon() {
      return this.isFullScreen ? 'minimize' : 'maximize';
    },
    toggleFullScreenText() {
      return this.isFullScreen
        ? this.$options.i18n.exitFullScreen
        : this.$options.i18n.enterFullScreen;
    },
    headerTopClass() {
      return this.isFullScreen ? 'gl-top-0' : 'top-app-header';
    },
  },
};
</script>
<template>
  <div class="gl-sticky gl-bg-white" :class="headerTopClass">
    <div class="gl-border gl-flex gl-flex-wrap gl-items-center">
      <gl-button
        class="gl-m-3"
        icon="scroll_down"
        :selected="isFollowing"
        :title="$options.i18n.scrollToBottom"
        :aria-label="$options.i18n.scrollToBottom"
        @click="$emit('scrollToBottom')"
      />
      <gl-button
        class="gl-m-3"
        icon="scroll_up"
        :title="$options.i18n.scrollToTop"
        :aria-label="$options.i18n.scrollToTop"
        @click="$emit('scrollToTop')"
      />
      <gl-button
        class="gl-m-3"
        :icon="toggleFullScreenIcon"
        :title="toggleFullScreenText"
        :aria-label="toggleFullScreenText"
        @click="$emit('toggleFullScreen')"
      />
      <slot></slot>
    </div>
  </div>
</template>
