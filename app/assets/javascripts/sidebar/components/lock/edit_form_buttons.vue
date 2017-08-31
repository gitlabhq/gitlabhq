<script>
export default {
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
    onOrOff() {
      return this.isLocked ? 'Unlock' : 'Lock';
    },

    updateLockedBool() {
      return !this.isLocked;
    },
  },
};
</script>

<template>
  <div class="lock-warning-message-actions">
    <button
      type="button"
      class="btn btn-default append-right-10"
      @click="toggleForm"
    >
      Cancel
    </button>

    <button
      type="button"
      class="btn btn-close"
      @click.prevent="updateLockedAttribute(updateLockedBool)"
    >
      {{ onOrOff }}
    </button>
  </div>
</template>
