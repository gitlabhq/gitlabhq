<script>
export default {
  provide() {
    // We can't use this.contentEditor due to bug in vue-apollo when
    // provide is called in beforeCreate
    // See https://github.com/vuejs/vue-apollo/pull/1153 for details

    // @vue-compat does not care to normalize propsData fields
    const contentEditor =
      this.$options.propsData.contentEditor || this.$options.propsData['content-editor'];

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
