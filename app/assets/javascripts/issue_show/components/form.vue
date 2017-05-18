<script>
  import eventHub from '../event_hub';
  import lockedWarning from './locked_warning.vue';
  import titleField from './fields/title.vue';
  import descriptionField from './fields/description.vue';
  import editActions from './edit_actions.vue';
  import confidentialCheckbox from './fields/confidential_checkbox.vue';

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
      lockedWarning,
      titleField,
      descriptionField,
      editActions,
      confidentialCheckbox,
    },
    methods: {
      closeForm() {
        eventHub.$emit('close.form');
        this.formState.lockedWarningVisible = false;
      },
    },
  };
</script>

<template>
  <form>
    <locked-warning
      v-if="formState.lockedWarningVisible"
      @closeForm="closeForm" />
    <title-field
      :form-state="formState" />
    <confidential-checkbox
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
