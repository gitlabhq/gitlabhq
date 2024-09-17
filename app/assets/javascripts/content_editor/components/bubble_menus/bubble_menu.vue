<script>
import { BubbleMenuPlugin } from '@tiptap/extension-bubble-menu';

export default {
  name: 'BubbleMenu',
  inject: ['tiptapEditor'],
  props: {
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
            strategy: 'fixed',
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
  <div>
    <slot v-if="menuVisible"></slot>
  </div>
</template>
