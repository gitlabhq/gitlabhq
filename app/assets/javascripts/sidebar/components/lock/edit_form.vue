<script>
import editFormButtons from './edit_form_buttons.vue';
import { __, sprintf } from '../../../locale';

export default {
  components: {
    editFormButtons,
  },
  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },
    issuableDisplayName: {
      required: true,
      type: String,
    },
  },
  computed: {
    lockWarning() {
      return sprintf(
        __(
          'Lock this %{issuableDisplayName}? Only <strong>project members</strong> will be able to comment.',
        ),
        { issuableDisplayName: this.issuableDisplayName },
      );
    },
    unlockWarning() {
      return sprintf(
        __(
          'Unlock this %{issuableDisplayName}? <strong>Everyone</strong> will be able to comment.',
        ),
        { issuableDisplayName: this.issuableDisplayName },
      );
    },
  },
};
</script>

<template>
  <div class="dropdown show">
    <div class="dropdown-menu sidebar-item-warning-message" data-testid="warning-text">
      <p v-if="isLocked" class="text" v-html="unlockWarning"></p>

      <p v-else class="text" v-html="lockWarning"></p>

      <edit-form-buttons :is-locked="isLocked" :issuable-display-name="issuableDisplayName" />
    </div>
  </div>
</template>
