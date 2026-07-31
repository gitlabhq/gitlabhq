<script>
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  name: 'ContentEditorProvider',
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
    return getSlotFunction(this)?.();
  },
});
</script>
