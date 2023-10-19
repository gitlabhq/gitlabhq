<script>
export default {
  provide() {
    const { contentEditor } = this;

    return {
      contentEditor,
      eventHub: contentEditor.eventHub,
      tiptapEditor: contentEditor.tiptapEditor,
    };
  },
  props: {
    contentEditor: {
      type: Object,
      required: true,
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
