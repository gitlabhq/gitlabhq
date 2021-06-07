<script>
import 'codemirror/lib/codemirror.css';
import '@toast-ui/editor/dist/toastui-editor.css';

import { EDITOR_TYPES, EDITOR_HEIGHT, EDITOR_PREVIEW_STYLE, CUSTOM_EVENTS } from './constants';
import AddImageModal from './modals/add_image/add_image_modal.vue';
import InsertVideoModal from './modals/insert_video_modal.vue';

import {
  registerHTMLToMarkdownRenderer,
  getEditorOptions,
  addCustomEventListener,
  removeCustomEventListener,
  addImage,
  getMarkdown,
  insertVideo,
} from './services/editor_service';

export default {
  components: {
    ToastEditor: () =>
      import(/* webpackChunkName: 'toast_editor' */ '@toast-ui/vue-editor').then(
        (toast) => toast.Editor,
      ),
    AddImageModal,
    InsertVideoModal,
  },
  props: {
    content: {
      type: String,
      required: true,
    },
    options: {
      type: Object,
      required: false,
      default: () => null,
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
    imageRoot: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      editorApi: null,
      previousMode: null,
    };
  },
  computed: {
    editorInstance() {
      return this.$refs.editor;
    },
    customEventListeners() {
      return [
        { event: CUSTOM_EVENTS.openAddImageModal, listener: this.onOpenAddImageModal },
        { event: CUSTOM_EVENTS.openInsertVideoModal, listener: this.onOpenInsertVideoModal },
      ];
    },
  },
  created() {
    this.editorOptions = getEditorOptions(this.options);
  },
  beforeDestroy() {
    this.removeListeners();
  },
  methods: {
    addListeners(editorApi) {
      this.customEventListeners.forEach(({ event, listener }) => {
        addCustomEventListener(editorApi, event, listener);
      });

      editorApi.eventManager.listen('changeMode', this.onChangeMode);
    },
    removeListeners() {
      this.customEventListeners.forEach(({ event, listener }) => {
        removeCustomEventListener(this.editorApi, event, listener);
      });

      this.editorApi.eventManager.removeEventHandler('changeMode', this.onChangeMode);
    },
    resetInitialValue(newVal) {
      this.editorInstance.invoke('setMarkdown', newVal);
    },
    onContentChanged() {
      this.$emit('input', getMarkdown(this.editorInstance));
    },
    onLoad(editorApi) {
      this.editorApi = editorApi;

      registerHTMLToMarkdownRenderer(editorApi);

      this.addListeners(editorApi);

      this.$emit('load', { formattedMarkdown: editorApi.getMarkdown() });
    },
    onOpenAddImageModal() {
      this.$refs.addImageModal.show();
    },
    onAddImage({ imageUrl, altText, file }) {
      const image = { imageUrl, altText };

      if (file) {
        this.$emit('uploadImage', { file, imageUrl });
      }

      addImage(this.editorInstance, image, file);
    },
    onOpenInsertVideoModal() {
      this.$refs.insertVideoModal.show();
    },
    onInsertVideo(url) {
      insertVideo(this.editorInstance, url);
    },
    onChangeMode(newMode) {
      this.$emit('modeChange', newMode);
    },
  },
};
</script>
<template>
  <div>
    <toast-editor
      ref="editor"
      :initial-value="content"
      :options="editorOptions"
      :preview-style="previewStyle"
      :initial-edit-type="initialEditType"
      :height="height"
      @change="onContentChanged"
      @load="onLoad"
    />
    <add-image-modal ref="addImageModal" :image-root="imageRoot" @addImage="onAddImage" />
    <insert-video-modal ref="insertVideoModal" @insertVideo="onInsertVideo" />
  </div>
</template>
