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
      monacoLoader(['vs/editor/editor.main'], () => {
        this.monaco = monaco;

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

            this.addMonacoEvents();
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

      this.monacoInstance.setModel(newModel);
    },
    addMonacoEvents() {
      this.monacoInstance.onKeyUp(() => {
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
