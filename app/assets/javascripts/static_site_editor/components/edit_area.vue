<script>
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import PublishToolbar from './publish_toolbar.vue';
import EditHeader from './edit_header.vue';
import EditDrawer from './edit_drawer.vue';
import UnsavedChangesConfirmDialog from './unsaved_changes_confirm_dialog.vue';
import parseSourceFile from '~/static_site_editor/services/parse_source_file';
import { EDITOR_TYPES } from '~/vue_shared/components/rich_content_editor/constants';
import imageRepository from '../image_repository';
import formatter from '../services/formatter';
import templater from '../services/templater';
import renderImage from '../services/renderers/render_image';

export default {
  components: {
    RichContentEditor,
    PublishToolbar,
    EditHeader,
    EditDrawer,
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
    branch: {
      type: String,
      required: true,
    },
    baseUrl: {
      type: String,
      required: true,
    },
    mounts: {
      type: Array,
      required: true,
    },
    project: {
      type: String,
      required: true,
    },
    imageRoot: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      parsedSource: parseSourceFile(this.preProcess(true, this.content)),
      editorMode: EDITOR_TYPES.wysiwyg,
      hasMatter: false,
      isDrawerOpen: false,
      isModified: false,
      isSaveable: false,
    };
  },
  imageRepository: imageRepository(),
  computed: {
    editableContent() {
      return this.parsedSource.content(this.isWysiwygMode);
    },
    editableMatter() {
      return this.isDrawerOpen ? this.parsedSource.matter() : {};
    },
    hasSettings() {
      return this.hasMatter && this.isWysiwygMode;
    },
    isWysiwygMode() {
      return this.editorMode === EDITOR_TYPES.wysiwyg;
    },
    customRenderers() {
      const imageRenderer = renderImage.build(
        this.mounts,
        this.project,
        this.branch,
        this.baseUrl,
        this.$options.imageRepository,
      );
      return {
        image: [imageRenderer],
      };
    },
  },
  created() {
    this.refreshEditHelpers();
  },
  methods: {
    preProcess(isWrap, value) {
      const formattedContent = formatter(value);
      const templatedContent = isWrap
        ? templater.wrap(formattedContent)
        : templater.unwrap(formattedContent);
      return templatedContent;
    },
    refreshEditHelpers() {
      const { isModified, hasMatter, isMatterValid } = this.parsedSource;
      this.isModified = isModified();
      this.hasMatter = hasMatter();
      const hasValidMatter = this.hasMatter ? isMatterValid() : true;
      this.isSaveable = this.isModified && hasValidMatter;
    },
    onDrawerOpen() {
      this.isDrawerOpen = true;
      this.refreshEditHelpers();
    },
    onDrawerClose() {
      this.isDrawerOpen = false;
      this.refreshEditHelpers();
    },
    onInputChange(newVal) {
      this.parsedSource.syncContent(newVal, this.isWysiwygMode);
      this.refreshEditHelpers();
    },
    onModeChange(mode) {
      this.editorMode = mode;

      const preProcessedContent = this.preProcess(this.isWysiwygMode, this.editableContent);
      this.$refs.editor.resetInitialValue(preProcessedContent);
    },
    onUpdateSettings(settings) {
      this.parsedSource.syncMatter(settings);
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
    <edit-drawer
      v-if="hasMatter"
      :is-open="isDrawerOpen"
      :settings="editableMatter"
      @close="onDrawerClose"
      @updateSettings="onUpdateSettings"
    />
    <rich-content-editor
      ref="editor"
      :content="editableContent"
      :initial-edit-type="editorMode"
      :image-root="imageRoot"
      :options="{ customRenderers }"
      class="mb-9 pb-6 h-100"
      @modeChange="onModeChange"
      @input="onInputChange"
      @uploadImage="onUploadImage"
    />
    <unsaved-changes-confirm-dialog :modified="isSaveable" />
    <publish-toolbar
      class="gl-fixed gl-left-0 gl-bottom-0 gl-w-full"
      :has-settings="hasSettings"
      :return-url="returnUrl"
      :saveable="isSaveable"
      :saving-changes="savingChanges"
      @editSettings="onDrawerOpen"
      @submit="onSubmit"
    />
  </div>
</template>
