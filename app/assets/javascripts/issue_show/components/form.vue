<script>
  import titleField from './fields/title.vue';
  import descriptionField from './fields/description.vue';
  import editActions from './edit_actions.vue';

  export default {
    props: {
      canDestroy: {
        type: Boolean,
        required: true,
      },
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
      titleField,
      descriptionField,
      editActions,
    },
  };
</script>

<template>
  <form>
    <title-field
      :form-state="formState" />
    <description-field
      :form-state="formState"
      :markdown-preview-url="markdownPreviewUrl"
      :markdown-docs="markdownDocs" />
    <edit-actions
      :form-state="formState"
      :can-destroy="canDestroy" />
  </form>
</template>
