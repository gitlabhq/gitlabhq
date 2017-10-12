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
    buttonText() {
      return this.isLocked ? this.__('Unlock') : this.__('Lock');
    },

    toggleLock() {
      return !this.isLocked;
    },
  },
};
</script>

<template>
  <div class="sidebar-item-warning-message-actions">
    <button
      type="button"
      class="btn btn-default append-right-10"
      @click="toggleForm"
    >
      {{ __('Cancel') }}
    </button>

    <button
      type="button"
      class="btn btn-close"
      @click.prevent="updateLockedAttribute(toggleLock)"
    >
      {{ buttonText }}
    </button>
  </div>
</template>
