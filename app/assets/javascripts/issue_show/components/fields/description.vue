<script>
  /* global Flash */
  import updateMixin from '../../mixins/update';
  import markdownField from '../../../vue_shared/components/markdown/field.vue';

  export default {
    mixins: [updateMixin],
    props: {
      store: {
        type: Object,
        required: true,
      },
      markdownPreviewUrl: {
        type: String,
        required: true,
      },
      markdownDocs: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        state: this.store.formState,
      };
    },
    components: {
      markdownField,
    },
    mounted() {
      this.$refs.textarea.focus();
    },
  };
</script>

<template>
  <div>
    <label
      class="sr-only"
      for="issue-description">
      Description
    </label>
    <markdown-field
      :markdown-preview-url="markdownPreviewUrl"
      :markdown-docs="markdownDocs">
      <textarea
        id="issue-description"
        class="note-textarea js-gfm-input js-autosize markdown-area"
        data-supports-slash-commands="false"
        aria-label="Description"
<<<<<<< HEAD
        v-model="state.description"
        ref="textatea"
=======
        v-model="formState.description"
        ref="textarea"
<<<<<<< HEAD
>>>>>>> 2927802... Focus the description field in the inline form when mounted
        slot="textarea">
=======
        slot="textarea"
<<<<<<< HEAD
        placeholder="Write a comment or drag your files here...">
>>>>>>> e20654f... fixed GFM references not working
=======
        placeholder="Write a comment or drag your files here..."
        @keydown.meta.enter="updateIssuable">
>>>>>>> 29fd130... enable meta+enter shortcut to quick submit
      </textarea>
    </markdown-field>
  </div>
</template>
