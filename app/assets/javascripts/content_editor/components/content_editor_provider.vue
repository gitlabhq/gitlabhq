<script>
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
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
});
</script>
