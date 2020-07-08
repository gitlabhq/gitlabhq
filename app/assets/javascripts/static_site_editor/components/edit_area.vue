<script>
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import PublishToolbar from './publish_toolbar.vue';
import EditHeader from './edit_header.vue';
import UnsavedChangesConfirmDialog from './unsaved_changes_confirm_dialog.vue';
import parseSourceFile from '~/static_site_editor/services/parse_source_file';
import { EDITOR_TYPES } from '~/vue_shared/components/rich_content_editor/constants';
import { DEFAULT_IMAGE_UPLOAD_PATH } from '../constants';
import imageRepository from '../image_repository';

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
      parsedSource: parseSourceFile(this.content),
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
    onInputChange(newVal) {
      this.parsedSource.sync(newVal, this.isWysiwygMode);
      this.isModified = this.parsedSource.isModified();
    },
    onModeChange(mode) {
      this.editorMode = mode;
      this.$refs.editor.resetInitialValue(this.editableContent);
    },
    onUploadImage({ file, imageUrl }) {
      this.$options.imageRepository.add(file, imageUrl);
    },
    onSubmit() {
      this.$emit('submit', {
        content: this.parsedSource.content(),
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
