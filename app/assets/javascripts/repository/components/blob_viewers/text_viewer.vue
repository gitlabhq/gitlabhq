<script>
export default {
  components: {
    SourceEditor: () =>
      import(/* webpackChunkName: 'SourceEditor' */ '~/vue_shared/components/source_editor.vue'),
  },
  props: {
    content: {
      type: String,
      required: true,
    },
    fileName: {
      type: String,
      required: true,
    },
    readOnly: {
      type: Boolean,
      required: true,
    },
  },
};
</script>
<template>
  <source-editor :value="content" :file-name="fileName" :editor-options="{ readOnly }" />
</template>
