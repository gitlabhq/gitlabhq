<script>
  import editFormButtons from './edit_form_buttons.vue';
  import issuableMixin from '../../../vue_shared/mixins/issuable';

  export default {
    components: {
      editFormButtons,
    },
    mixins: [
      issuableMixin,
    ],
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
    <div class="dropdown-menu sidebar-item-warning-message">
      <p
        class="text"
<<<<<<< HEAD
        v-if="isLocked"
      >
=======
        v-if="isLocked">
>>>>>>> upstream/master
        Unlock this {{ issuableDisplayName }}?
        <strong>Everyone</strong>
        will be able to comment.
      </p>

      <p
        class="text"
<<<<<<< HEAD
        v-else
      >
=======
        v-else>
>>>>>>> upstream/master
        Lock this {{ issuableDisplayName }}?
        Only
        <strong>project members</strong>
        will be able to comment.
      </p>

      <edit-form-buttons
        :is-locked="isLocked"
        :toggle-form="toggleForm"
        :update-locked-attribute="updateLockedAttribute"
      />
    </div>
  </div>
</template>
