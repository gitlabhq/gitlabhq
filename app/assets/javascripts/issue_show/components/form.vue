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
    },
    components: {
      titleField,
      editActions,
    },
  };
</script>

<template>
  <form>
    <title-field
      :form-state="formState" />
    <edit-actions
      :can-destroy="canDestroy" />
  </form>
</template>
