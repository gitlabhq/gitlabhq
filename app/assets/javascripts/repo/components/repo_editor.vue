<script>
/* global monaco */
import { mapGetters, mapActions } from 'vuex';
import flash from '../../flash';
import monacoLoader from '../monaco_loader';

export default {
  destroyed() {
    if (this.monacoInstance) {
      this.monacoInstance.destroy();
    }
  },
  mounted() {
    if (this.monaco) {
      this.initMonaco();
    } else {
      monacoLoader(['vs/editor/editor.main', 'vs/editor/common/diff/diffComputer'], (_, { DiffComputer }) => {
        this.monaco = monaco;
        this.DiffComputer = DiffComputer;

        this.initMonaco();
      });
    }
  },
  methods: {
    ...mapActions([
      'getRawFileData',
      'changeFileContent',
    ]),
    initMonaco() {
      if (this.shouldHideEditor) return;

      if (this.monacoInstance) {
        this.monacoInstance.setModel(null);
      }

      this.getRawFileData(this.activeFile)
        .then(() => {
          if (!this.monacoInstance) {
            this.monacoInstance = this.monaco.editor.create(this.$el, {
              model: null,
              readOnly: false,
              contextmenu: true,
              scrollBeyondLastLine: false,
            });

            this.languages = this.monaco.languages.getLanguages();
          }

          this.setupEditor();
        })
        .catch(() => flash('Error setting up monaco. Please try again.'));
    },
    setupEditor() {
      if (!this.activeFile) return;
      const content = this.activeFile.content !== '' ? this.activeFile.content : this.activeFile.raw;

      const foundLang = this.languages.find(lang =>
        lang.extensions && lang.extensions.indexOf(this.activeFileExtension) === 0,
      );
      const newModel = this.monaco.editor.createModel(
        content, foundLang ? foundLang.id : 'plaintext',
      );
      const originalLines = this.monaco.editor.createModel(
        this.activeFile.raw, foundLang ? foundLang.id : 'plaintext',
      ).getLinesContent();

      this.monacoInstance.setModel(newModel);
      this.decorations = [];

      const modifiedType = (change) => {
        if (change.originalEndLineNumber === 0) {
          return 'added';
        } else if (change.modifiedEndLineNumber === 0) {
          return 'removed';
        }

        return 'modified';
      };

      this.monacoModelChangeContents = newModel.onDidChangeContent(() => {
        const diffComputer = new this.DiffComputer(
          originalLines,
          newModel.getLinesContent(),
          {
            shouldPostProcessCharChanges: true,
            shouldIgnoreTrimWhitespace: true,
            shouldMakePrettyDiff: true,
          },
        );

        this.decorations = this.monacoInstance.deltaDecorations(this.decorations,
          diffComputer.computeDiff().map(change => ({
            range: new monaco.Range(
              change.modifiedStartLineNumber,
              1,
              !change.modifiedEndLineNumber ?
                change.modifiedStartLineNumber : change.modifiedEndLineNumber,
              1,
            ),
            options: {
              isWholeLine: true,
              linesDecorationsClassName: `dirty-diff dirty-diff-${modifiedType(change)}`,
            },
          })),
        );

        this.changeFileContent({
          file: this.activeFile,
          content: this.monacoInstance.getValue(),
        });
      });
    },
  },
  watch: {
    activeFile(oldVal, newVal) {
      if (newVal && !newVal.active) {
        this.initMonaco();
      }
    },
  },
  computed: {
    ...mapGetters([
      'activeFile',
      'activeFileExtension',
    ]),
    shouldHideEditor() {
      return this.activeFile.binary && !this.activeFile.raw;
    },
  },
};
</script>

<template>
  <div
    id="ide"
    class="blob-viewer-container blob-editor-container"
  >
    <div
      v-if="shouldHideEditor"
      v-html="activeFile.html"
    >
    </div>
  </div>
</template>
