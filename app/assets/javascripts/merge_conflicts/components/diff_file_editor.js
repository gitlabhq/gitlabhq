/* eslint-disable comma-dangle, quote-props, no-useless-computed-key, object-shorthand, no-new, no-param-reassign, max-len */
/* global ace */

import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

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
      };
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
    mounted() {
      if (this.file.loadEditor) {
        this.loadEditor();
      }
    },
    methods: {
      loadEditor() {
        this.loading = true;

        axios.get(this.file.content_path)
          .then(({ data }) => {
            const content = this.$el.querySelector('pre');
            const fileContent = document.createTextNode(data.content);

            content.textContent = fileContent.textContent;

            this.originalContent = data.content;
            this.fileLoaded = true;
            this.editor = ace.edit(content);
            this.editor.$blockScrolling = Infinity; // Turn off annoying warning
            this.editor.getSession().setMode(`ace/mode/${data.blob_ace_mode}`);
            this.editor.on('change', () => {
              this.saveDiffResolution();
            });
            this.saveDiffResolution();
            this.loading = false;
          })
          .catch(() => {
            flash(__('An error occurred while loading the file'));
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
