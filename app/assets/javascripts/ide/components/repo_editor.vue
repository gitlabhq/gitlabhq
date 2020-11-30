<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { viewerInformationForPath } from '~/vue_shared/components/content_viewer/lib/viewer_utils';
import { deprecatedCreateFlash as flash } from '~/flash';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import {
  WEBIDE_MARK_FILE_CLICKED,
  WEBIDE_MARK_REPO_EDITOR_START,
  WEBIDE_MARK_REPO_EDITOR_FINISH,
  WEBIDE_MEASURE_REPO_EDITOR,
  WEBIDE_MEASURE_FILE_AFTER_INTERACTION,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import eventHub from '../eventhub';
import {
  leftSidebarViews,
  viewerTypes,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
} from '../constants';
import Editor from '../lib/editor';
import FileTemplatesBar from './file_templates/bar.vue';
import { __ } from '~/locale';
import { extractMarkdownImagesFromEntries } from '../stores/utils';
import { getFileEditorOrDefault } from '../stores/modules/editor/utils';
import { getPathParent, readFileAsDataURL, registerSchema, isTextFile } from '../utils';
import { getRulesWithTraversal } from '../lib/editorconfig/parser';
import mapRulesToMonaco from '../lib/editorconfig/rules_mapper';

export default {
  name: 'RepoEditor',
  components: {
    ContentViewer,
    DiffViewer,
    FileTemplatesBar,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      content: '',
      images: {},
      rules: {},
    };
  },
  computed: {
    ...mapState('rightPane', {
      rightPaneIsOpen: 'isOpen',
    }),
    ...mapState('editor', ['fileEditors']),
    ...mapState([
      'viewer',
      'panelResizing',
      'currentActivityView',
      'renderWhitespaceInCode',
      'editorTheme',
      'entries',
      'currentProjectId',
    ]),
    ...mapGetters([
      'currentMergeRequest',
      'getStagedFile',
      'isEditModeActive',
      'isCommitModeActive',
      'currentBranch',
      'getJsonSchemaForPath',
    ]),
    ...mapGetters('fileTemplates', ['showFileTemplatesBar']),
    fileEditor() {
      return getFileEditorOrDefault(this.fileEditors, this.file.path);
    },
    shouldHideEditor() {
      return this.file && !this.file.loading && !isTextFile(this.file);
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
      return this.fileEditor.viewMode === FILE_VIEW_MODE_EDITOR;
    },
    isPreviewViewMode() {
      return this.fileEditor.viewMode === FILE_VIEW_MODE_PREVIEW;
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
    showEditor() {
      return !this.shouldHideEditor && this.isEditorViewMode;
    },
    editorOptions() {
      return {
        renderWhitespace: this.renderWhitespaceInCode ? 'all' : 'none',
        theme: this.editorTheme,
      };
    },
    currentBranchCommit() {
      return this.currentBranch?.commit.id;
    },
    previewMode() {
      return viewerInformationForPath(this.file.path);
    },
    fileType() {
      return this.previewMode?.id || '';
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

        if (this.currentActivityView !== leftSidebarViews.edit.name) {
          this.updateEditor({
            viewMode: FILE_VIEW_MODE_EDITOR,
          });
        }
      }
    },
    currentActivityView() {
      if (this.currentActivityView !== leftSidebarViews.edit.name) {
        this.updateEditor({
          viewMode: FILE_VIEW_MODE_EDITOR,
        });
      }
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
    showContentViewer(val) {
      if (!val) return;

      if (this.fileType === 'markdown') {
        const { content, images } = extractMarkdownImagesFromEntries(this.file, this.entries);
        this.content = content;
        this.images = images;
      } else {
        this.content = this.file.content || this.file.raw;
        this.images = {};
      }
    },
  },
  beforeDestroy() {
    this.editor.dispose();
  },
  mounted() {
    if (!this.editor) {
      this.editor = Editor.create(this.$store, this.editorOptions);
    }
    this.initEditor();

    // listen in capture phase to be able to override Monaco's behaviour.
    window.addEventListener('paste', this.onPaste, true);
  },
  destroyed() {
    window.removeEventListener('paste', this.onPaste, true);
  },
  methods: {
    ...mapActions([
      'getFileData',
      'getRawFileData',
      'changeFileContent',
      'removePendingTab',
      'triggerFilesChange',
      'addTempImage',
    ]),
    ...mapActions('editor', ['updateFileEditor']),
    initEditor() {
      performanceMarkAndMeasure({ mark: WEBIDE_MARK_REPO_EDITOR_START });
      if (this.shouldHideEditor && (this.file.content || this.file.raw)) {
        return;
      }

      this.editor.clearEditor();

      this.registerSchemaForFile();

      Promise.all([this.fetchFileData(), this.fetchEditorconfigRules()])
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
        toggleLoading: false,
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
          this.editor.createDiffInstance(this.$refs.editor);
        }

        this.setupEditor();
      });
    },
    setupEditor() {
      if (!this.file || !this.editor.instance || this.file.loading) return;

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

      this.model.updateOptions(this.rules);

      this.model.onChange(model => {
        const { file } = model;
        if (!file.active) return;

        const monacoModel = model.getModel();
        const content = monacoModel.getValue();
        this.changeFileContent({ path: file.path, content });
      });

      // Handle Cursor Position
      this.editor.onPositionChange((instance, e) => {
        this.updateEditor({
          editorRow: e.position.lineNumber,
          editorColumn: e.position.column,
        });
      });

      this.editor.setPosition({
        lineNumber: this.fileEditor.editorRow,
        column: this.fileEditor.editorColumn,
      });

      // Handle File Language
      this.updateEditor({
        fileLanguage: this.model.language,
      });

      this.$emit('editorSetup');
      if (performance.getEntriesByName(WEBIDE_MARK_FILE_CLICKED).length) {
        eventHub.$emit(WEBIDE_MEASURE_FILE_AFTER_INTERACTION);
      } else {
        performanceMarkAndMeasure({
          mark: WEBIDE_MARK_REPO_EDITOR_FINISH,
          measures: [
            {
              name: WEBIDE_MEASURE_REPO_EDITOR,
              start: WEBIDE_MARK_REPO_EDITOR_START,
            },
          ],
        });
      }
    },
    refreshEditorDimensions() {
      if (this.showEditor) {
        this.editor.updateDimensions();
      }
    },
    fetchEditorconfigRules() {
      return getRulesWithTraversal(this.file.path, path => {
        const entry = this.entries[path];
        if (!entry) return Promise.resolve(null);

        const content = entry.content || entry.raw;
        if (content) return Promise.resolve(content);

        return this.getFileData({ path: entry.path, makeFileActive: false }).then(() =>
          this.getRawFileData({ path: entry.path }),
        );
      }).then(rules => {
        this.rules = mapRulesToMonaco(rules);
      });
    },
    onPaste(event) {
      const editor = this.editor.instance;
      const reImage = /^image\/(png|jpg|jpeg|gif)$/;
      const file = event.clipboardData.files[0];

      if (editor.hasTextFocus() && this.fileType === 'markdown' && reImage.test(file?.type)) {
        // don't let the event be passed on to Monaco.
        event.preventDefault();
        event.stopImmediatePropagation();

        return readFileAsDataURL(file).then(content => {
          const parentPath = getPathParent(this.file.path);
          const path = `${parentPath ? `${parentPath}/` : ''}${file.name}`;

          return this.addTempImage({ name: path, rawPath: content }).then(({ name: fileName }) => {
            this.editor.replaceSelectedText(`![${fileName}](./${fileName})`);
          });
        });
      }

      // do nothing if no image is found in the clipboard
      return Promise.resolve();
    },
    registerSchemaForFile() {
      const schema = this.getJsonSchemaForPath(this.file.path);
      registerSchema(schema);
    },
    updateEditor(data) {
      // Looks like our model wrapper `.dispose` causes the monaco editor to emit some position changes after
      // when disposing. We want to ignore these by only capturing editor changes that happen to the currently active
      // file.
      if (!this.file.active) {
        return;
      }

      this.updateFileEditor({ path: this.file.path, data });
    },
  },
  viewerTypes,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
};
</script>

<template>
  <div id="ide" class="blob-viewer-container blob-editor-container">
    <div v-if="!shouldHideEditor && isEditModeActive" class="ide-mode-tabs clearfix">
      <ul class="nav-links float-left border-bottom-0">
        <li :class="editTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="updateEditor({ viewMode: $options.FILE_VIEW_MODE_EDITOR })"
          >
            {{ __('Edit') }}
          </a>
        </li>
        <li v-if="previewMode" :class="previewTabCSS">
          <a
            href="javascript:void(0);"
            role="button"
            @click.prevent="updateEditor({ viewMode: $options.FILE_VIEW_MODE_PREVIEW })"
            >{{ previewMode.previewTitle }}</a
          >
        </li>
      </ul>
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
      data-qa-selector="editor_container"
      @focusout="triggerFilesChange"
    ></div>
    <content-viewer
      v-if="showContentViewer"
      :content="content"
      :images="images"
      :path="file.rawPath || file.path"
      :file-path="file.path"
      :file-size="file.size"
      :project-path="currentProjectId"
      :commit-sha="currentBranchCommit"
      :type="fileType"
    />
    <diff-viewer
      v-if="showDiffViewer"
      :diff-mode="file.mrChange.diffMode"
      :new-path="file.mrChange.new_path"
      :new-sha="currentMergeRequest.sha"
      :old-path="file.mrChange.old_path"
      :old-sha="currentMergeRequest.baseCommitSha"
      :project-path="currentProjectId"
    />
  </div>
</template>
