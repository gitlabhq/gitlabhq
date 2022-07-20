<script>
export default {
  provide() {
    // We can't use this.contentEditor due to bug in vue-apollo when
    // provide is called in beforeCreate
    // See https://github.com/vuejs/vue-apollo/pull/1153 for details
    const { contentEditor } = this.$options.propsData;

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
