<script>
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import { CiSchemaExtension } from '~/editor/extensions/editor_ci_schema_ext';

export default {
  components: {
    EditorLite,
  },
  inject: ['projectPath', 'projectNamespace'],
  inheritAttrs: false,
  props: {
    ciConfigPath: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: null,
    },
  },
  methods: {
    onEditorReady() {
      const editorInstance = this.$refs.editor.getEditor();

      editorInstance.use(new CiSchemaExtension());
      editorInstance.registerCiSchema({
        projectPath: this.projectPath,
        projectNamespace: this.projectNamespace,
        ref: this.commitSha,
      });
    },
  },
};
</script>
<template>
  <div class="gl-border-solid gl-border-gray-100 gl-border-1">
    <editor-lite
      ref="editor"
      :file-name="ciConfigPath"
      v-bind="$attrs"
      @editor-ready="onEditorReady"
      v-on="$listeners"
    />
  </div>
</template>
