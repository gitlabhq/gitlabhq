<script>
/* global monaco */
import { mapGetters, mapActions } from 'vuex';
import Helper from '../helpers/repo_helper';
import flash from '../../flash';

export default {
  destroyed() {
    if (this.monacoInstance) {
      this.monacoInstance.destroy();
    }
  },
  mounted() {
    this.initMonaco();
  },
  methods: {
    ...mapActions([
      'getRawFileData',
      'changeFileContent',
    ]),
    initMonaco() {
      if (this.monacoInstance) {
        this.monacoInstance.setModel(null);
      }

      this.getRawFileData(this.activeFile)
        .then(() => {
          if (!this.monacoInstance) {
            this.monacoInstance = Helper.monaco.editor.create(this.$el, {
              model: null,
              readOnly: false,
              contextmenu: true,
              scrollBeyondLastLine: false,
            });

            this.languages = Helper.monaco.languages.getLanguages();

            this.addMonacoEvents();
          }

          this.setupEditor();
        })
        .catch(() => flash('Error setting up monaco. Please try again.'));
    },
    setupEditor() {
      const foundLang = this.languages.find(lang =>
        lang.extensions && lang.extensions.indexOf(this.activeFileExtension) === 0,
      );
      const newModel = Helper.monaco.editor.createModel(
        this.activeFile.raw, foundLang ? foundLang.id : 'plaintext',
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
      if (newVal.active) {
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
<div id="ide" v-if='!shouldHideEditor'></div>
</template>
