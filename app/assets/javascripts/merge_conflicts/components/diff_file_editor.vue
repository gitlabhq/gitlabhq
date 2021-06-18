<script>
import { GlButton } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapActions } from 'vuex';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { INTERACTIVE_RESOLVE_MODE } from '../constants';

export default {
  components: {
    GlButton,
  },
  props: {
    file: {
      type: Object,
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
    ...mapActions(['setFileResolveMode', 'setPromptConfirmationState', 'updateFile']),
    loadEditor() {
      const EditorPromise = import(/* webpackChunkName: 'SourceEditor' */ '~/editor/source_editor');
      const DataPromise = axios.get(this.file.content_path);

      Promise.all([EditorPromise, DataPromise])
        .then(
          ([
            { default: SourceEditor },
            {
              data: { content, new_path: path },
            },
          ]) => {
            const contentEl = this.$el.querySelector('.editor');

            this.originalContent = content;
            this.fileLoaded = true;

            this.editor = new SourceEditor().createInstance({
              el: contentEl,
              blobPath: path,
              blobContent: content,
            });
            this.editor.onDidChangeModelContent(debounce(this.saveDiffResolution.bind(this), 250));
          },
        )
        .catch(() => {
          createFlash({
            message: __('An error occurred while loading the file'),
          });
        });
    },
    saveDiffResolution() {
      this.saved = true;

      this.updateFile({
        ...this.file,
        content: this.editor.getValue(),
        resolveEditChanged: this.file.content !== this.originalContent,
        promptDiscardConfirmation: false,
      });
    },
    resetEditorContent() {
      if (this.fileLoaded) {
        this.editor.setValue(this.originalContent);
      }
    },
    acceptDiscardConfirmation(file) {
      this.setPromptConfirmationState({ file, promptDiscardConfirmation: false });
      this.setFileResolveMode({ file, mode: INTERACTIVE_RESOLVE_MODE });
    },
    cancelDiscardConfirmation(file) {
      this.setPromptConfirmationState({ file, promptDiscardConfirmation: false });
    },
  },
};
</script>
<template>
  <div v-show="file.showEditor">
    <div v-if="file.promptDiscardConfirmation" class="discard-changes-alert">
      {{ __('Are you sure you want to discard your changes?') }}
      <div class="gl-ml-3 gl-display-inline-block">
        <gl-button
          size="small"
          variant="danger"
          category="secondary"
          @click="acceptDiscardConfirmation(file)"
        >
          {{ __('Discard changes') }}
        </gl-button>
        <gl-button size="small" @click="cancelDiscardConfirmation(file)">
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </div>
    <div :class="classObject" class="editor-wrap">
      <div class="editor" style="height: 350px" data-editor-loading="true"></div>
    </div>
  </div>
</template>
