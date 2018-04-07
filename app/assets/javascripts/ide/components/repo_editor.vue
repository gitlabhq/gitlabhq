<script>
/* global monaco */
import { mapState, mapGetters, mapActions } from 'vuex';
import flash from '~/flash';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import monacoLoader from '../monaco_loader';
import Editor from '../lib/editor';
import IdeFileButtons from './ide_file_buttons.vue';

export default {
  components: {
    ContentViewer,
    IdeFileButtons,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['rightPanelCollapsed', 'viewer', 'delayViewerUpdated', 'panelResizing']),
    ...mapGetters(['currentMergeRequest', 'getStagedFile']),
    shouldHideEditor() {
      return this.file && this.file.binary && !this.file.raw;
    },
    editTabCSS() {
      return {
        active: this.file.viewMode === 'edit',
      };
    },
    previewTabCSS() {
      return {
        active: this.file.viewMode === 'preview',
      };
    },
  },
  watch: {
    file(oldVal, newVal) {
      // Compare key to allow for files opened in review mode to be cached differently
      if (newVal.key !== this.file.key) {
        this.initMonaco();
      }
    },
    rightPanelCollapsed() {
      this.editor.updateDimensions();
    },
    viewer() {
      this.createEditorInstance();
    },
    panelResizing() {
      if (!this.panelResizing) {
        this.editor.updateDimensions();
      }
    },
  },
  beforeDestroy() {
    this.editor.dispose();
  },
  mounted() {
    if (this.editor && monaco) {
      this.initMonaco();
    } else {
      monacoLoader(['vs/editor/editor.main'], () => {
        this.editor = Editor.create(monaco);

        this.initMonaco();
      });
    }
  },
  methods: {
    ...mapActions([
      'getRawFileData',
      'changeFileContent',
      'setFileLanguage',
      'setEditorPosition',
      'setFileViewMode',
      'setFileEOL',
      'updateViewer',
      'updateDelayViewerUpdated',
    ]),
    initMonaco() {
      if (this.shouldHideEditor) return;

      this.editor.clearEditor();

      this.getRawFileData({
        path: this.file.path,
        baseSha: this.currentMergeRequest ? this.currentMergeRequest.baseCommitSha : '',
      })
        .then(() => {
          const viewerPromise = this.delayViewerUpdated
            ? this.updateViewer(this.file.pending ? 'diff' : 'editor')
            : Promise.resolve();

          return viewerPromise;
        })
        .then(() => {
          this.updateDelayViewerUpdated(false);
          this.createEditorInstance();
        })
        .catch(err => {
          flash('Error setting up monaco. Please try again.', 'alert', document, null, false, true);
          throw err;
        });
    },
    createEditorInstance() {
      this.editor.dispose();

      this.$nextTick(() => {
        if (this.viewer === 'editor') {
          this.editor.createInstance(this.$refs.editor);
        } else {
          this.editor.createDiffInstance(this.$refs.editor);
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

      if (this.viewer === 'mrdiff') {
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
};
</script>

<template>
  <div
    id="ide"
    class="blob-viewer-container blob-editor-container"
  >
    <div class="ide-mode-tabs clearfix">
      <ul
        class="nav-links pull-left"
        v-if="!shouldHideEditor">
        <li :class="editTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="setFileViewMode({ file, viewMode: 'edit' })">
            <template v-if="viewer === 'editor'">
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
      <ide-file-buttons
        :file="file"
      />
    </div>
    <div
      v-show="!shouldHideEditor && file.viewMode === 'edit'"
      ref="editor"
      class="multi-file-editor-holder"
    >
    </div>
    <content-viewer
      v-if="shouldHideEditor || file.viewMode === 'preview'"
      :content="file.content || file.raw"
      :path="file.rawPath"
      :file-size="file.size"
      :project-path="file.projectId"/>
  </div>
</template>
