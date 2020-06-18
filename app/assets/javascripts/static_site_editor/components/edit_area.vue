<script>
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import PublishToolbar from './publish_toolbar.vue';
import EditHeader from './edit_header.vue';
import UnsavedChangesConfirmDialog from './unsaved_changes_confirm_dialog.vue';
import parseSourceFile from '~/static_site_editor/services/parse_source_file';
import { EDITOR_TYPES } from '~/vue_shared/components/rich_content_editor/constants';

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
  },
  data() {
    return {
      saveable: false,
      parsedSource: parseSourceFile(this.content),
      editorMode: EDITOR_TYPES.wysiwyg,
    };
  },
  computed: {
    editableContent() {
      return this.parsedSource.editable;
    },
    editableKey() {
      return this.isWysiwygMode ? 'body' : 'raw';
    },
    isWysiwygMode() {
      return this.editorMode === EDITOR_TYPES.wysiwyg;
    },
    modified() {
      return this.isWysiwygMode
        ? this.parsedSource.isModifiedBody()
        : this.parsedSource.isModifiedRaw();
    },
  },
  methods: {
    syncSource() {
      if (this.isWysiwygMode) {
        this.parsedSource.syncBody();
        return;
      }

      this.parsedSource.syncRaw();
    },
    onModeChange(mode) {
      this.editorMode = mode;
      this.syncSource();
    },
    onSubmit() {
      this.syncSource();
      this.$emit('submit', { content: this.editableContent.raw });
    },
  },
};
</script>
<template>
  <div class="d-flex flex-grow-1 flex-column h-100">
    <edit-header class="py-2" :title="title" />
    <rich-content-editor
      v-model="editableContent[editableKey]"
      :initial-edit-type="editorMode"
      class="mb-9 h-100"
      @modeChange="onModeChange"
    />
    <unsaved-changes-confirm-dialog :modified="modified" />
    <publish-toolbar
      class="gl-fixed gl-left-0 gl-bottom-0 gl-w-full"
      :return-url="returnUrl"
      :saveable="modified"
      :saving-changes="savingChanges"
      @submit="onSubmit"
    />
  </div>
</template>
