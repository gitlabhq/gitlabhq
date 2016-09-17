((global) => {
  global.diffFileEditor = Vue.extend({
    props: ['file', 'loadFile'],
    template: '#diff-file-editor',
    data() {
      return {
        originalContent: '',
        saved: false,
        loading: false,
        fileLoaded: false
      }
    },
    computed: {
      classObject() {
        return {
          'load-file': this.loadFile,
          'saved': this.saved,
          'is-loading': this.loading
        };
      }
    },
    watch: {
      loadFile(val) {
        const self = this;

        this.resetEditorContent();

        if (!val || this.fileLoaded || this.loading) {
          return
        }

        this.loading = true;

        $.get(this.file.content_path)
          .done((file) => {

            let content = self.$el.querySelector('pre');
            let fileContent = document.createTextNode(file.content);

            content.textContent = fileContent.textContent;

            self.originalContent = file.content;
            self.fileLoaded = true;
            self.editor = ace.edit(content);
            self.editor.$blockScrolling = Infinity; // Turn off annoying warning
            self.editor.on('change', () => {
              self.saveDiffResolution();
            });
            self.saveDiffResolution();
          })
          .fail(() => {
            console.log('error');
          })
          .always(() => {
            self.loading = false;
          });
      }
    },
    methods: {
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
      }
    }
  });

})(window.gl || (window.gl = {}));
