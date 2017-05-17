<script>
  import titleField from './fields/title.vue';
  import descriptionField from './fields/description.vue';
  import editActions from './edit_actions.vue';
  import projectMove from './fields/project_move.vue';

  export default {
    props: {
      canMove: {
        type: Boolean,
        required: true,
      },
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
      projectsAutocompleteUrl: {
        type: String,
        required: true,
      },
    },
    components: {
      titleField,
      descriptionField,
      editActions,
      projectMove,
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
    <project-move
      v-if="canMove"
      :form-state="formState"
      :projects-autocomplete-url="projectsAutocompleteUrl" />
    <edit-actions
      :can-destroy="canDestroy" />
  </form>
</template>
