<script>
import MarkdownField from '../../vue_shared/components/markdown/field.vue';

export default {
  props: {
    noteBody: {
      type: String,
      required: false,
      default: '',
    },
    updateHandler: {
      type: Function,
      required: true,
    },
    cancelHandler: {
      type: Function,
      required: true,
    },
    saveButtonTitle: {
      type: String,
      required: false,
      default: 'Save comment',
    }
  },
  data() {
    return {
      note: this.noteBody,
      markdownPreviewUrl: '',
      markdownDocsUrl: '',
    };
  },
  components: {
    MarkdownField,
  },
  methods: {
    handleUpdate() {
      this.updateHandler({
        note: this.note,
      });
    },
  },
  mounted() {
    const issuableDataEl = document.getElementById('js-issuable-app-initial-data');
    const issueData = JSON.parse(issuableDataEl.innerHTML.replace(/&quot;/g, '"'));
    const { markdownDocs, markdownPreviewUrl } = issueData;

    this.markdownDocsUrl = markdownDocs;
    this.markdownPreviewUrl = markdownPreviewUrl;
    this.$refs.textarea.focus();
  },
};
</script>

<template>
  <div class="note-edit-form">
    <form class="edit-note common-note-form">
      <markdown-field
        :markdown-preview-url="markdownPreviewUrl"
        :markdown-docs="markdownDocsUrl"
        :addSpacingClasses="false">
        <textarea
          id="note-body"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          data-supports-slash-commands="false"
          aria-label="Description"
          v-model="note"
          ref="textarea"
          slot="textarea"
          placeholder="Write a comment or drag your files here..."
          @keydown.meta.enter="handleUpdate">
        </textarea>
      </markdown-field>
      <div class="note-form-actions clearfix">
        <button
          @click="handleUpdate"
          type="button"
          class="btn btn-nr btn-save">
          {{saveButtonTitle}}
        </button>
        <button
          @click="cancelHandler"
          class="btn btn-nr btn-cancel"
          type="button">
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>
