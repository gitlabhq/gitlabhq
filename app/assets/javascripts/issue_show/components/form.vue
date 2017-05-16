<script>
  import titleField from './fields/title.vue';
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
      issuableTemplates: {
        type: Array,
        required: false,
        default: () => [],
      },
    },
    components: {
      titleField,
      editActions,
    },
    issuableTemplates: {
      type: Array,
      required: true,
      default: () => [],
    },
  };
</script>

<template>
  <form>
    <title-field
      :form-state="formState"
      :issuable-templates="issuableTemplates" />
    <edit-actions
      :can-destroy="canDestroy" />
  </form>
</template>
