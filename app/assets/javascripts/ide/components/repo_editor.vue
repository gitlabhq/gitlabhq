<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import flash from '~/flash';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import { activityBarViews, viewerTypes } from '../constants';
import Editor from '../lib/editor';
import ExternalLink from './external_link.vue';

export default {
  components: {
    ContentViewer,
    DiffViewer,
    ExternalLink,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'rightPanelCollapsed',
      'viewer',
      'panelResizing',
      'currentActivityView',
      'rightPane',
    ]),
    ...mapGetters([
      'currentMergeRequest',
      'getStagedFile',
      'isEditModeActive',
      'isCommitModeActive',
      'isReviewModeActive',
      'isPathBinary',
    ]),
    shouldHideEditor() {
      return this.file && this.isPathBinary(this.file.name) && !this.file.content;
    },
    showContentViewer() {
      return (
        (this.shouldHideEditor || this.file.viewMode === 'preview') &&
        (this.viewer !== viewerTypes.mr || !this.file.mrChange)
      );
    },
    showDiffViewer() {
      return this.shouldHideEditor && this.file.mrChange && this.viewer === viewerTypes.mr;
    },
    editTabCSS() {
      return {
        active: this.file.viewMode === 'editor',
      };
    },
    previewTabCSS() {
      return {
        active: this.file.viewMode === 'preview',
      };
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
            viewMode: 'editor',
          });
        }
      }
    },
    currentActivityView() {
      if (this.currentActivityView !== activityBarViews.edit) {
        this.setFileViewMode({
          file: this.file,
          viewMode: 'editor',
        });
      }
    },
    rightPanelCollapsed() {
      this.editor.updateDimensions();
    },
    viewer() {
      if (!this.file.pending) {
        this.createEditorInstance();
      }
    },
    panelResizing() {
      if (!this.panelResizing) {
        this.editor.updateDimensions();
      }
    },
    rightPane() {
      this.editor.updateDimensions();
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
    ]),
    initEditor() {
      if (this.shouldHideEditor) return;

      this.editor.clearEditor();

      this.getFileData({
        path: this.file.path,
        makeFileActive: false,
      })
        .then(() =>
          this.getRawFileData({
            path: this.file.path,
            baseSha: this.currentMergeRequest ? this.currentMergeRequest.baseCommitSha : '',
          }),
        )
        .then(() => {
          this.createEditorInstance();
        })
        .catch(err => {
          flash('Error setting up editor. Please try again.', 'alert', document, null, false, true);
          throw err;
        });
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
  },
  viewerTypes,
};
</script>

<template>
  <div
    id="ide"
    class="blob-viewer-container blob-editor-container"
  >
    <div class="ide-mode-tabs clearfix" >
      <ul
        v-if="!shouldHideEditor && isEditModeActive"
        class="nav-links float-left"
      >
        <li :class="editTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="setFileViewMode({ file, viewMode: 'editor' })">
            <template v-if="viewer === $options.viewerTypes.edit">
              {{ __('Edit') }}
            </template>
            <template v-else>
              {{ __('Review') }}
            </template>
          </a>
        </li>
        <li
          v-if="file.previewMode"
          :class="previewTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="setFileViewMode({ file, viewMode:'preview' })">
            {{ file.previewMode.previewTitle }}
          </a>
        </li>
      </ul>
      <external-link
        :file="file"
      />
    </div>
    <div
      v-show="!shouldHideEditor && file.viewMode ==='editor'"
      ref="editor"
      :class="{
        'is-readonly': isCommitModeActive,
        'is-deleted': file.deleted,
        'is-added': file.tempFile
      }"
      class="multi-file-editor-holder"
    >
    </div>
    <content-viewer
      v-if="showContentViewer"
      :content="file.content || file.raw"
      :path="file.rawPath || file.path"
      :file-size="file.size"
      :project-path="file.projectId"/>
    <diff-viewer
      v-if="showDiffViewer"
      :diff-mode="file.mrChange.diffMode"
      :new-path="file.mrChange.new_path"
      :new-sha="currentMergeRequest.sha"
      :old-path="file.mrChange.old_path"
      :old-sha="currentMergeRequest.baseCommitSha"
      :project-path="file.projectId"/>
  </div>
</template>
