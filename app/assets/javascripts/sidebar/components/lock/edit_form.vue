<script>
import editFormButtons from './edit_form_buttons.vue';

export default {
  components: {
    editFormButtons,
  },

  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },

    toggleForm: {
      required: true,
      type: Function,
    },

    updateLockedAttribute: {
      required: true,
      type: Function,
    },
  },
};
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu lock-warning-message">
      <div>
        <p v-if="isLocked">
          Unlock this issue?
          <strong>everyone</strong>
          will be able to comment.
        </p>

        <p v-else>
          Lock this issue? Only
          <strong>project memebers</strong>
          will be able to comment.
        </p>

        <edit-form-buttons
          :is-locked="isLocked"
          :toggle-form="toggleForm"
          :update-locked-attribute="updateLockedAttribute"
        />
      </div>
    </div>
  </div>
</template>
