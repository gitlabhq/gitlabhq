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
  watch: {
    value(newVal) {
      const isSameMode = this.previousMode === this.editorApi.currentMode;
      if (!isSameMode) {
        /*
        The ToastUI Editor consumes its content via the `initial-value` prop and then internally
        manages changes. If we desire the `v-model` to work as expected, we need to manually call
        `setMarkdown`. However, if we do this in each v-model change we'll continually prevent
        the editor from internally managing changes. Thus we use the `previousMode` flag as
        confirmation to actually update its internals. This is initially designed so that front
        matter is excluded from editing in wysiwyg mode, but included in markdown mode.
        */
        this.editorInstance.invoke('setMarkdown', newVal);
        this.previousMode = this.editorApi.currentMode;
      }
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
    onContentChanged() {
      this.$emit('input', getMarkdown(this.editorInstance));
    },
    onLoad(editorApi) {
      this.editorApi = editorApi;

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
    onAddImage(image) {
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
