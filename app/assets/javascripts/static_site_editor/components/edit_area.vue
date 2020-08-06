<script>
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import PublishToolbar from './publish_toolbar.vue';
import EditHeader from './edit_header.vue';
import UnsavedChangesConfirmDialog from './unsaved_changes_confirm_dialog.vue';
import parseSourceFile from '~/static_site_editor/services/parse_source_file';
import { EDITOR_TYPES } from '~/vue_shared/components/rich_content_editor/constants';
import { DEFAULT_IMAGE_UPLOAD_PATH } from '../constants';
import imageRepository from '../image_repository';
import formatter from '../services/formatter';
import templater from '../services/templater';

export default {
  components: {
    RichContentEditor,
    PublishToolbar,
    EditHeader,
    UnsavedChangesConfirmDialog,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    savingChanges: {
      type: Boolean,
      required: true,
    },
    returnUrl: {
      type: String,
      required: false,
      default: '',
    },
    imageRoot: {
      type: String,
      required: false,
      default: DEFAULT_IMAGE_UPLOAD_PATH,
      validator: prop => prop.endsWith('/'),
    },
  },
  data() {
    return {
      saveable: false,
      parsedSource: parseSourceFile(this.preProcess(true, this.content)),
      editorMode: EDITOR_TYPES.wysiwyg,
      isModified: false,
    };
  },
  imageRepository: imageRepository(),
  computed: {
    editableContent() {
      return this.parsedSource.content(this.isWysiwygMode);
    },
    isWysiwygMode() {
      return this.editorMode === EDITOR_TYPES.wysiwyg;
    },
  },
  methods: {
    preProcess(isWrap, value) {
      const formattedContent = formatter(value);
      const templatedContent = isWrap
        ? templater.wrap(formattedContent)
        : templater.unwrap(formattedContent);
      return templatedContent;
    },
    onInputChange(newVal) {
      this.parsedSource.sync(newVal, this.isWysiwygMode);
      this.isModified = this.parsedSource.isModified();
    },
    onModeChange(mode) {
      this.editorMode = mode;

      const preProcessedContent = this.preProcess(this.isWysiwygMode, this.editableContent);
      this.$refs.editor.resetInitialValue(preProcessedContent);
    },
    onUploadImage({ file, imageUrl }) {
      this.$options.imageRepository.add(file, imageUrl);
    },
    onSubmit() {
      const preProcessedContent = this.preProcess(false, this.parsedSource.content());
      this.$emit('submit', {
        content: preProcessedContent,
        images: this.$options.imageRepository.getAll(),
      });
    },
  },
};
</script>
<template>
  <div class="d-flex flex-grow-1 flex-column h-100">
    <edit-header class="py-2" :title="title" />
    <rich-content-editor
      ref="editor"
      :content="editableContent"
      :initial-edit-type="editorMode"
      :image-root="imageRoot"
      class="mb-9 h-100"
      @modeChange="onModeChange"
      @input="onInputChange"
      @uploadImage="onUploadImage"
    />
    <unsaved-changes-confirm-dialog :modified="isModified" />
    <publish-toolbar
      class="gl-fixed gl-left-0 gl-bottom-0 gl-w-full"
      :return-url="returnUrl"
      :saveable="isModified"
      :saving-changes="savingChanges"
      @submit="onSubmit"
    />
  </div>
</template>
