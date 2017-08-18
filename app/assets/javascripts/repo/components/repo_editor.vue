<script>
/* global monaco */
import Store from '../stores/repo_store';
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';

const RepoEditor = {
  data: () => Store,

  destroyed() {
    if (Helper.monacoInstance) {
      Helper.monacoInstance.destroy();
    }
  },

  mounted() {
    Service.getRaw(this.activeFile.raw_path)
      .then((rawResponse) => {
        Store.blobRaw = rawResponse.data;
        Store.activeFile.plain = rawResponse.data;

        const monacoInstance = Helper.monaco.editor.create(this.$el, {
          model: null,
          readOnly: false,
          contextmenu: false,
        });

        Helper.monacoInstance = monacoInstance;

        this.addMonacoEvents();

        this.setupEditor();
      })
      .catch(Helper.loadingError);
  },

  methods: {
    setupEditor() {
      this.showHide();

      Helper.setMonacoModelFromLanguage();
    },

    showHide() {
      if (!this.openedFiles.length || (this.binary && !this.activeFile.raw)) {
        this.$el.style.display = 'none';
      } else {
        this.$el.style.display = 'inline-block';
      }
    },

    addMonacoEvents() {
      Helper.monacoInstance.onMouseUp(this.onMonacoEditorMouseUp);
      Helper.monacoInstance.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
    },

    onMonacoEditorKeysPressed() {
      Store.setActiveFileContents(Helper.monacoInstance.getValue());
    },

    onMonacoEditorMouseUp(e) {
      if (!e.target.position) return;
      const lineNumber = e.target.position.lineNumber;
      if (e.target.element.classList.contains('line-numbers')) {
        location.hash = `L${lineNumber}`;
        Store.activeLine = lineNumber;

        Helper.monacoInstance.setPosition({
          lineNumber: this.activeLine,
          column: 1,
        });
      }
    },
  },

  watch: {
    dialog: {
      handler(obj) {
        const newObj = obj;
        if (newObj.status) {
          newObj.status = false;
          this.openedFiles = this.openedFiles.map((file) => {
            const f = file;
            if (f.active) {
              this.blobRaw = f.plain;
            }
            f.changed = false;
            delete f.newContent;

            return f;
          });
          this.editMode = false;
          Store.toggleBlobView();
        }
      },
      deep: true,
    },

    blobRaw() {
      if (Helper.monacoInstance && !this.isTree) {
        this.setupEditor();
      }
    },
  },
  computed: {
    shouldHideEditor() {
      return !this.openedFiles.length || (this.binary && !this.activeFile.raw);
    },
  },
};

export default RepoEditor;
</script>

<template>
<div id="ide" v-if='!shouldHideEditor'></div>
</template>
