((global) => {

  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.diffFileEditor = Vue.extend({
    props: {
      file: Object,
      onCancelDiscardConfirmation: Function,
      onAcceptDiscardConfirmation: Function
    },
    data() {
      return {
        saved: false,
        loading: false,
        fileLoaded: false,
        originalContent: '',
      }
    },
    computed: {
      classObject() {
        return {
          'saved': this.saved,
          'is-loading': this.loading
        };
      }
    },
    watch: {
      ['file.showEditor'](val) {
        this.resetEditorContent();

        if (!val || this.fileLoaded || this.loading) {
          return;
        }

        this.loadEditor();
      }
    },
    ready() {
      if (this.file.loadEditor) {
        this.loadEditor();
      }
    },
    methods: {
      loadEditor() {
        this.loading = true;

        $.get(this.file.content_path)
          .done((file) => {
            let content = this.$el.querySelector('pre');
            let fileContent = document.createTextNode(file.content);

            content.textContent = fileContent.textContent;

            this.originalContent = file.content;
            this.fileLoaded = true;
            this.editor = ace.edit(content);
            this.editor.$blockScrolling = Infinity; // Turn off annoying warning
            this.editor.on('change', () => {
              this.saveDiffResolution();
            });
            this.saveDiffResolution();
          })
          .fail(() => {
            console.log('error');
          })
          .always(() => {
            this.loading = false;
          });
      },
      saveDiffResolution() {
        this.saved = true;

        // This probably be better placed in the data provider
        this.file.content = this.editor.getValue();
        this.file.resolveEditChanged = this.file.content !== this.originalContent;
        this.file.promptDiscardConfirmation = false;
      },
      resetEditorContent() {
        if (this.fileLoaded) {
          this.editor.setValue(this.originalContent, -1);
        }
      },
      cancelDiscardConfirmation(file) {
        this.onCancelDiscardConfirmation(file);
      },
      acceptDiscardConfirmation(file) {
        this.onAcceptDiscardConfirmation(file);
      }
    }
  });

})(window.gl || (window.gl = {}));
