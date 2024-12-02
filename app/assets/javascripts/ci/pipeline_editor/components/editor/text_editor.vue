<script>
import { EDITOR_READY_EVENT } from '~/editor/constants';
import { CiSchemaExtension } from '~/editor/extensions/source_editor_ci_schema_ext';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import eventHub, { SCROLL_EDITOR_TO_BOTTOM } from '~/ci/pipeline_editor/event_hub';
import { SOURCE_EDITOR_DEBOUNCE } from '../../constants';

export default {
  editorOptions: {
    // Quick suggestions is so that monaco can provide
    // autocomplete for keywords
    quickSuggestions: true,
  },
  debounceValue: SOURCE_EDITOR_DEBOUNCE,
  components: {
    SourceEditor,
  },
  inject: ['ciConfigPath'],
  inheritAttrs: false,
  created() {
    eventHub.$on(SCROLL_EDITOR_TO_BOTTOM, this.scrollEditorToBottom);
  },
  beforeDestroy() {
    eventHub.$off(SCROLL_EDITOR_TO_BOTTOM, this.scrollEditorToBottom);
  },
  methods: {
    onCiConfigUpdate(content) {
      this.$emit('updateCiConfig', content);
    },
    registerCiSchema({ detail: { instance } }) {
      instance.use({ definition: CiSchemaExtension });
      instance.registerCiSchema();
    },
    scrollEditorToBottom() {
      const editor = this.$refs.editor.getEditor();
      editor.setScrollTop(editor.getScrollHeight());
    },
  },
  readyEvent: EDITOR_READY_EVENT,
};
</script>
<template>
  <div class="gl-border-1 !gl-border-t-0 gl-border-solid gl-border-default">
    <source-editor
      ref="editor"
      :debounce-value="$options.debounceValue"
      :editor-options="$options.editorOptions"
      :file-name="ciConfigPath"
      v-bind="$attrs"
      @[$options.readyEvent]="registerCiSchema($event)"
      @input="onCiConfigUpdate"
      v-on="$listeners"
    />
  </div>
</template>
