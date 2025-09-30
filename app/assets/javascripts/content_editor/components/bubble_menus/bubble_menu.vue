<script>
import { BubbleMenuPlugin } from '@tiptap/extension-bubble-menu';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'BubbleMenu',
  mixins: [glFeatureFlagsMixin()],
  inject: ['tiptapEditor'],
  props: {
    ariaLabel: {
      type: String,
      required: false,
      default: undefined,
    },
    pluginKey: {
      type: String,
      required: true,
    },
    shouldShow: {
      type: Function,
      required: true,
    },
    tippyOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      menuVisible: false,
    };
  },
  async mounted() {
    await this.$nextTick();

    const strategy = this.glFeatures.projectStudioEnabled ? 'absolute' : 'fixed';

    this.tiptapEditor.registerPlugin(
      BubbleMenuPlugin({
        pluginKey: this.pluginKey,
        editor: this.tiptapEditor,
        element: this.$el,
        shouldShow: this.shouldShow,
        tippyOptions: {
          ...this.tippyOptions,
          onShow: (...args) => {
            this.$emit('show', ...args);
            this.menuVisible = true;
          },
          onHidden: (...args) => {
            this.$emit('hidden', ...args);
            this.menuVisible = false;
          },
          popperOptions: {
            strategy,
          },
          maxWidth: '400px',
        },
      }),
    );
  },

  beforeDestroy() {
    this.tiptapEditor.unregisterPlugin(this.pluginKey);
  },
};
</script>
<template>
  <div :aria-label="ariaLabel">
    <slot v-if="menuVisible"></slot>
  </div>
</template>
