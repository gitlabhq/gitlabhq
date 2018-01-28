<script>
  import updateMixin from '../../mixins/update';
  import markdownField from '../../../vue_shared/components/markdown/field.vue';

  export default {
    components: {
      markdownField,
    },
    mixins: [updateMixin],
    props: {
      formState: {
        type: Object,
        required: true,
      },
      markdownPreviewPath: {
        type: String,
        required: true,
      },
      markdownDocsPath: {
        type: String,
        required: true,
      },
      canAttachFile: {
        type: Boolean,
        required: false,
        default: true,
      },
      enableAutocomplete: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    mounted() {
      this.$refs.textarea.focus();
    },
  };
</script>

<template>
  <div class="common-note-form">
    <label
      class="sr-only"
      for="issue-description">
      Description
    </label>
    <markdown-field
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :can-attach-file="canAttachFile"
      :enable-autocomplete="enableAutocomplete"
    >
      <textarea
        id="issue-description"
        class="note-textarea js-gfm-input js-autosize markdown-area"
        data-supports-quick-actions="false"
        aria-label="Description"
        v-model="formState.description"
        ref="textarea"
        slot="textarea"
        placeholder="Write a comment or drag your files here..."
        @keydown.meta.enter="updateIssuable"
        @keydown.ctrl.enter="updateIssuable">
      </textarea>
    </markdown-field>
  </div>
</template>
