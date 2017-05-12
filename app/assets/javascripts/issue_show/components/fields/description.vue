<script>
  /* global Flash */
  import markdownField from '../../../vue_shared/components/markdown/field.vue';

  export default {
    props: {
      store: {
        type: Object,
        required: true,
      },
      markdownPreviewUrl: {
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
      :markdown-preview-url="markdownPreviewUrl">
      <textarea
        id="issue-description"
        class="note-textarea js-gfm-input js-autosize markdown-area"
        data-supports-slash-commands="false"
        aria-label="Description"
        v-model="state.description"
        ref="textatea"
        slot="textarea">
      </textarea>
    </markdown-field>
  </div>
</template>
