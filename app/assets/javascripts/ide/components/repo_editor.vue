<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { viewerInformationForPath } from '~/vue_shared/components/content_viewer/lib/viewer_utils';
import flash from '~/flash';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import {
  activityBarViews,
  viewerTypes,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
} from '../constants';
import Editor from '../lib/editor';
import ExternalLink from './external_link.vue';
import FileTemplatesBar from './file_templates/bar.vue';
import { __ } from '~/locale';

export default {
  components: {
    ContentViewer,
    DiffViewer,
    ExternalLink,
    FileTemplatesBar,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState('rightPane', {
      rightPaneIsOpen: 'isOpen',
    }),
    ...mapState(['rightPanelCollapsed', 'viewer', 'panelResizing', 'currentActivityView']),
    ...mapGetters([
      'currentMergeRequest',
      'getStagedFile',
      'isEditModeActive',
      'isCommitModeActive',
      'isReviewModeActive',
    ]),
    ...mapGetters('fileTemplates', ['showFileTemplatesBar']),
    shouldHideEditor() {
      return this.file && this.file.binary;
    },
    showContentViewer() {
      return (
        (this.shouldHideEditor || this.isPreviewViewMode) &&
        (this.viewer !== viewerTypes.mr || !this.file.mrChange)
      );
    },
    showDiffViewer() {
      return this.shouldHideEditor && this.file.mrChange && this.viewer === viewerTypes.mr;
    },
    isEditorViewMode() {
      return this.file.viewMode === FILE_VIEW_MODE_EDITOR;
    },
    isPreviewViewMode() {
      return this.file.viewMode === FILE_VIEW_MODE_PREVIEW;
    },
    editTabCSS() {
      return {
        active: this.isEditorViewMode,
      };
    },
    previewTabCSS() {
      return {
        active: this.isPreviewViewMode,
      };
    },
    fileType() {
      const info = viewerInformationForPath(this.file.path);
      return (info && info.id) || '';
    },
    showEditor() {
      return !this.shouldHideEditor && this.isEditorViewMode;
    },
  },
  watch: {
    file(newVal, oldVal) {
      if (oldVal.pending) {
        this.removePendingTab(oldVal);
      }

      // Compare key to allow for files opened in review mode to be cached differently
      if (oldVal.key !== this.file.key) {
        this.initEditor();

        if (this.currentActivityView !== activityBarViews.edit) {
          this.setFileViewMode({
            file: this.file,
            viewMode: FILE_VIEW_MODE_EDITOR,
          });
        }
      }
    },
    currentActivityView() {
      if (this.currentActivityView !== activityBarViews.edit) {
        this.setFileViewMode({
          file: this.file,
          viewMode: FILE_VIEW_MODE_EDITOR,
        });
      }
    },
    rightPanelCollapsed() {
      this.refreshEditorDimensions();
    },
    viewer() {
      if (!this.file.pending) {
        this.createEditorInstance();
      }
    },
    panelResizing() {
      if (!this.panelResizing) {
        this.refreshEditorDimensions();
      }
    },
    rightPaneIsOpen() {
      this.refreshEditorDimensions();
    },
    showEditor(val) {
      if (val) {
        // We need to wait for the editor to actually be rendered.
        this.$nextTick(() => this.refreshEditorDimensions());
      }
    },
  },
  beforeDestroy() {
    this.editor.dispose();
  },
  mounted() {
    if (!this.editor) {
      this.editor = Editor.create();
    }
    this.initEditor();
  },
  methods: {
    ...mapActions([
      'getFileData',
      'getRawFileData',
      'changeFileContent',
      'setFileLanguage',
      'setEditorPosition',
      'setFileViewMode',
      'setFileEOL',
      'updateViewer',
      'removePendingTab',
      'triggerFilesChange',
    ]),
    initEditor() {
      if (this.shouldHideEditor && (this.file.content || this.file.raw)) {
        return;
      }

      this.editor.clearEditor();

      this.fetchFileData()
        .then(() => {
          this.createEditorInstance();
        })
        .catch(err => {
          flash(
            __('Error setting up editor. Please try again.'),
            'alert',
            document,
            null,
            false,
            true,
          );
          throw err;
        });
    },
    fetchFileData() {
      if (this.file.tempFile) {
        return Promise.resolve();
      }

      return this.getFileData({
        path: this.file.path,
        makeFileActive: false,
      }).then(() =>
        this.getRawFileData({
          path: this.file.path,
        }),
      );
    },
    createEditorInstance() {
      this.editor.dispose();

      this.$nextTick(() => {
        if (this.viewer === viewerTypes.edit) {
          this.editor.createInstance(this.$refs.editor);
        } else {
          this.editor.createDiffInstance(this.$refs.editor, !this.isReviewModeActive);
        }

        this.setupEditor();
      });
    },
    setupEditor() {
      if (!this.file || !this.editor.instance) return;

      const head = this.getStagedFile(this.file.path);

      this.model = this.editor.createModel(
        this.file,
        this.file.staged && this.file.key.indexOf('unstaged-') === 0 ? head : null,
      );

      if (this.viewer === viewerTypes.mr && this.file.mrChange) {
        this.editor.attachMergeRequestModel(this.model);
      } else {
        this.editor.attachModel(this.model);
      }

      this.model.onChange(model => {
        const { file } = model;

        if (file.active) {
          this.changeFileContent({
            path: file.path,
            content: model.getModel().getValue(),
          });
        }
      });

      // Handle Cursor Position
      this.editor.onPositionChange((instance, e) => {
        this.setEditorPosition({
          editorRow: e.position.lineNumber,
          editorColumn: e.position.column,
        });
      });

      this.editor.setPosition({
        lineNumber: this.file.editorRow,
        column: this.file.editorColumn,
      });

      // Handle File Language
      this.setFileLanguage({
        fileLanguage: this.model.language,
      });

      // Get File eol
      this.setFileEOL({
        eol: this.model.eol,
      });
    },
    refreshEditorDimensions() {
      if (this.showEditor) {
        this.editor.updateDimensions();
      }
    },
  },
  viewerTypes,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
};
</script>

<template>
  <div id="ide" class="blob-viewer-container blob-editor-container">
    <div class="ide-mode-tabs clearfix">
      <ul v-if="!shouldHideEditor && isEditModeActive" class="nav-links float-left">
        <li :class="editTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="setFileViewMode({ file, viewMode: $options.FILE_VIEW_MODE_EDITOR })"
          >
            <template v-if="viewer === $options.viewerTypes.edit">{{ __('Edit') }}</template>
            <template v-else>{{ __('Review') }}</template>
          </a>
        </li>
        <li v-if="file.previewMode" :class="previewTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="setFileViewMode({ file, viewMode: $options.FILE_VIEW_MODE_PREVIEW })"
            >{{ file.previewMode.previewTitle }}</a
          >
        </li>
      </ul>
      <external-link :file="file" />
    </div>
    <file-templates-bar v-if="showFileTemplatesBar(file.name)" />
    <div
      v-show="showEditor"
      ref="editor"
      :class="{
        'is-readonly': isCommitModeActive,
        'is-deleted': file.deleted,
        'is-added': file.tempFile,
      }"
      class="multi-file-editor-holder"
      @focusout="triggerFilesChange"
    ></div>
    <content-viewer
      v-if="showContentViewer"
      :content="file.content || file.raw"
      :path="file.rawPath || file.path"
      :file-path="file.path"
      :file-size="file.size"
      :project-path="file.projectId"
      :type="fileType"
    />
    <diff-viewer
      v-if="showDiffViewer"
      :diff-mode="file.mrChange.diffMode"
      :new-path="file.mrChange.new_path"
      :new-sha="currentMergeRequest.sha"
      :old-path="file.mrChange.old_path"
      :old-sha="currentMergeRequest.baseCommitSha"
      :project-path="file.projectId"
    />
  </div>
</template>
