<script>
import 'codemirror/lib/codemirror.css';
import '@toast-ui/editor/dist/toastui-editor.css';

import AddImageModal from './modals/add_image_modal.vue';
import {
  EDITOR_OPTIONS,
  EDITOR_TYPES,
  EDITOR_HEIGHT,
  EDITOR_PREVIEW_STYLE,
  CUSTOM_EVENTS,
} from './constants';

import {
  addCustomEventListener,
  removeCustomEventListener,
  addImage,
  getMarkdown,
} from './editor_service';

export default {
  components: {
    ToastEditor: () =>
      import(/* webpackChunkName: 'toast_editor' */ '@toast-ui/vue-editor').then(
        toast => toast.Editor,
      ),
    AddImageModal,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    options: {
      type: Object,
      required: false,
      default: () => EDITOR_OPTIONS,
    },
    initialEditType: {
      type: String,
      required: false,
      default: EDITOR_TYPES.wysiwyg,
    },
    height: {
      type: String,
      required: false,
      default: EDITOR_HEIGHT,
    },
    previewStyle: {
      type: String,
      required: false,
      default: EDITOR_PREVIEW_STYLE,
    },
  },
  computed: {
    editorOptions() {
      return { ...EDITOR_OPTIONS, ...this.options };
    },
    editorInstance() {
      return this.$refs.editor;
    },
  },
  beforeDestroy() {
    removeCustomEventListener(
      this.editorInstance,
      CUSTOM_EVENTS.openAddImageModal,
      this.onOpenAddImageModal,
    );
  },
  methods: {
    onContentChanged() {
      this.$emit('input', getMarkdown(this.editorInstance));
    },
    onLoad(editorInstance) {
      addCustomEventListener(
        editorInstance,
        CUSTOM_EVENTS.openAddImageModal,
        this.onOpenAddImageModal,
      );
    },
    onOpenAddImageModal() {
      this.$refs.addImageModal.show();
    },
    onAddImage(image) {
      addImage(this.editorInstance, image);
    },
  },
};
</script>
<template>
  <div>
    <toast-editor
      ref="editor"
      :initial-value="value"
      :options="editorOptions"
      :preview-style="previewStyle"
      :initial-edit-type="initialEditType"
      :height="height"
      @change="onContentChanged"
      @load="onLoad"
    />
    <add-image-modal ref="addImageModal" @addImage="onAddImage" />
  </div>
</template>
