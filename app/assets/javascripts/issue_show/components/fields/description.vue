<script>
  /* global Flash */
  import markdownField from '../../../vue_shared/components/markdown/field.vue';

  export default {
    props: {
      formState: {
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
    components: {
      markdownField,
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
      :markdown-preview-url="markdownPreviewUrl"
      :markdown-docs="markdownDocs">
      <textarea
        id="issue-description"
        class="note-textarea js-gfm-input js-autosize markdown-area"
        data-supports-slash-commands="false"
        aria-label="Description"
        v-model="formState.description"
        ref="textatea"
        slot="textarea">
      </textarea>
    </markdown-field>
  </div>
</template>
