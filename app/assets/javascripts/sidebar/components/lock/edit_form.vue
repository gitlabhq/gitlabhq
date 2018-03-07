<script>
  import editFormButtons from './edit_form_buttons.vue';
  import issuableMixin from '../../../vue_shared/mixins/issuable';
  import { __, sprintf } from '../../../locale';

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
    computed: {
      lockWarning() {
        return sprintf(__('Lock this %{issuableDisplayName}? Only <strong>project members</strong> will be able to comment.'), { issuableDisplayName: this.issuableDisplayName });
      },
      unlockWarning() {
        return sprintf(__('Unlock this %{issuableDisplayName}? <strong>Everyone</strong> will be able to comment.'), { issuableDisplayName: this.issuableDisplayName });
      },
    },
  };
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <p
        class="text"
        v-if="isLocked"
        v-html="unlockWarning">
      </p>

      <p
        class="text"
        v-else
        v-html="lockWarning">
      </p>

      <edit-form-buttons
        :is-locked="isLocked"
        :toggle-form="toggleForm"
        :update-locked-attribute="updateLockedAttribute"
      />
    </div>
  </div>
</template>
