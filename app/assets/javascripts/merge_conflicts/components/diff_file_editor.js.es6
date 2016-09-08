((global) => {
  global.diffFileEditor = Vue.extend({
    props: ['file', 'loadFile'],
    template: '#diff-file-editor',
    data() {
      return {
        originalState: '',
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

        if (!val || this.fileLoaded || this.loading) {
          return
        }

        this.loading = true;

        $.get(this.file.content_path)
          .done((file) => {
            $(self.$el).find('textarea').val(file.content);

            self.originalState = file.content;
            self.fileLoaded = true;
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
        this.file.content = this.$el.querySelector('textarea').value;
        this.file.resolveEditChanged = this.file.content !== this.originalState;
        this.file.promptDiscardConfirmation = false;
      },
      onInput() {
        this.saveDiffResolution();
      }
    }
  });

})(window.gl || (window.gl = {}));
