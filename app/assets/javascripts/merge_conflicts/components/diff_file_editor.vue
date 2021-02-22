<script>
import { debounce } from 'lodash';
import { deprecatedCreateFlash as flash } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default {
  props: {
    file: {
      type: Object,
      required: true,
    },
    onCancelDiscardConfirmation: {
      type: Function,
      required: true,
    },
    onAcceptDiscardConfirmation: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      saved: false,
      fileLoaded: false,
      originalContent: '',
    };
  },
  computed: {
    classObject() {
      return {
        saved: this.saved,
      };
    },
  },
  watch: {
    'file.showEditor': function showEditorWatcher(val) {
      this.resetEditorContent();

      if (!val || this.fileLoaded) {
        return;
      }

      this.loadEditor();
    },
  },
  mounted() {
    if (this.file.loadEditor) {
      this.loadEditor();
    }
  },
  methods: {
    loadEditor() {
      const EditorPromise = import(/* webpackChunkName: 'EditorLite' */ '~/editor/editor_lite');
      const DataPromise = axios.get(this.file.content_path);

      Promise.all([EditorPromise, DataPromise])
        .then(
          ([
            { default: EditorLite },
            {
              data: { content, new_path: path },
            },
          ]) => {
            const contentEl = this.$el.querySelector('.editor');

            this.originalContent = content;
            this.fileLoaded = true;

            this.editor = new EditorLite().createInstance({
              el: contentEl,
              blobPath: path,
              blobContent: content,
            });
            this.editor.onDidChangeModelContent(debounce(this.saveDiffResolution.bind(this), 250));
          },
        )
        .catch(() => {
          flash(__('An error occurred while loading the file'));
        });
    },
    saveDiffResolution() {
      this.saved = true;

      // This probably be better placed in the data provider
      /* eslint-disable vue/no-mutating-props */
      this.file.content = this.editor.getValue();
      this.file.resolveEditChanged = this.file.content !== this.originalContent;
      this.file.promptDiscardConfirmation = false;
      /* eslint-enable vue/no-mutating-props */
    },
    resetEditorContent() {
      if (this.fileLoaded) {
        this.editor.setValue(this.originalContent);
      }
    },
    cancelDiscardConfirmation(file) {
      this.onCancelDiscardConfirmation(file);
    },
    acceptDiscardConfirmation(file) {
      this.onAcceptDiscardConfirmation(file);
    },
  },
};
</script>
<template>
  <div v-show="file.showEditor" class="diff-editor-wrap">
    <div v-if="file.promptDiscardConfirmation" class="discard-changes-alert-wrap">
      <div class="discard-changes-alert">
        {{ __('Are you sure you want to discard your changes?') }}
        <div class="discard-actions">
          <button
            class="btn btn-sm btn-danger-secondary gl-button"
            @click="acceptDiscardConfirmation(file)"
          >
            {{ __('Discard changes') }}
          </button>
          <button class="btn btn-default btn-sm gl-button" @click="cancelDiscardConfirmation(file)">
            {{ __('Cancel') }}
          </button>
        </div>
      </div>
    </div>
    <div :class="classObject" class="editor-wrap">
      <div class="editor" style="height: 350px" data-editor-loading="true"></div>
    </div>
  </div>
</template>
