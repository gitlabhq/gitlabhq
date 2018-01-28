<script>
  import editFormButtons from './edit_form_buttons.vue';

  export default {
    components: {
      editFormButtons,
    },
    props: {
      isConfidential: {
        required: true,
        type: Boolean,
      },
      toggleForm: {
        required: true,
        type: Function,
      },
      updateConfidentialAttribute: {
        required: true,
        type: Function,
      },
    },
  };
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p v-if="!isConfidential">
          You are going to turn on the confidentiality. This means that only team members with
          <strong>at least Reporter access</strong>
          are able to see and leave comments on the issue.
        </p>
        <p v-else>
          You are going to turn off the confidentiality. This means
          <strong>everyone</strong>
          will be able to see and leave a comment on this issue.
        </p>
        <edit-form-buttons
          :is-confidential="isConfidential"
          :toggle-form="toggleForm"
          :update-confidential-attribute="updateConfidentialAttribute"
        />
      </div>
    </div>
  </div>
</template>
