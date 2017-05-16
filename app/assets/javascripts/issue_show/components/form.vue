<script>
  import titleField from './fields/title.vue';
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
    },
    components: {
      titleField,
      editActions,
      confidentialCheckbox,
    },
  };
</script>

<template>
  <form>
    <title-field
      :form-state="formState" />
    <confidential-checkbox
      :form-state="formState" />
    <edit-actions
      :can-destroy="canDestroy" />
  </form>
</template>
