<script>
import 'codemirror/lib/codemirror.css';
import '@toast-ui/editor/dist/toastui-editor.css';

import AddImageModal from './modals/add_image/add_image_modal.vue';
import {
  EDITOR_OPTIONS,
  EDITOR_TYPES,
  EDITOR_HEIGHT,
  EDITOR_PREVIEW_STYLE,
  CUSTOM_EVENTS,
} from './constants';

import {
  registerHTMLToMarkdownRenderer,
  addCustomEventListener,
  removeCustomEventListener,
  addImage,
  getMarkdown,
} from './services/editor_service';

import { getUrl } from './services/image_service';

export default {
  components: {
    ToastEditor: () =>
      import(/* webpackChunkName: 'toast_editor' */ '@toast-ui/vue-editor').then(
        toast => toast.Editor,
      ),
    AddImageModal,
  },
  props: {
    content: {
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
  data() {
    return {
      editorApi: null,
      previousMode: null,
    };
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
      this.editorApi,
      CUSTOM_EVENTS.openAddImageModal,
      this.onOpenAddImageModal,
    );

    this.editorApi.eventManager.removeEventHandler('changeMode', this.onChangeMode);
  },
  methods: {
    resetInitialValue(newVal) {
      this.editorInstance.invoke('setMarkdown', newVal);
    },
    onContentChanged() {
      this.$emit('input', getMarkdown(this.editorInstance));
    },
    onLoad(editorApi) {
      this.editorApi = editorApi;

      registerHTMLToMarkdownRenderer(editorApi);
      addCustomEventListener(
        this.editorApi,
        CUSTOM_EVENTS.openAddImageModal,
        this.onOpenAddImageModal,
      );

      this.editorApi.eventManager.listen('changeMode', this.onChangeMode);
    },
    onOpenAddImageModal() {
      this.$refs.addImageModal.show();
    },
    onAddImage({ imageUrl, altText, file }) {
      const image = { imageUrl, altText };

      if (file) {
        image.imageUrl = getUrl(file);
        // TODO - persist images locally (local image repository)
        // TODO - ensure that the actual repo URL for the image is used in Markdown mode
        // TODO - upload images to the project repository (on submit)
      }

      addImage(this.editorInstance, image);
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
    <add-image-modal ref="addImageModal" @addImage="onAddImage" />
  </div>
</template>
