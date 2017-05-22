<script>
  import lockedWarning from './locked_warning.vue';
  import titleField from './fields/title.vue';
  import descriptionField from './fields/description.vue';
  import editActions from './edit_actions.vue';
  import projectMove from './fields/project_move.vue';
  import confidentialCheckbox from './fields/confidential_checkbox.vue';

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
      lockedWarning,
      titleField,
      descriptionField,
      editActions,
      projectMove,
      confidentialCheckbox,
    },
  };
</script>

<template>
  <form>
    <locked-warning v-if="formState.lockedWarningVisible" />
    <title-field
      :form-state="formState" />
    <confidential-checkbox
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
      :form-state="formState"
      :can-destroy="canDestroy" />
  </form>
</template>
