<script>
export default {
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
  computed: {
    toggleButtonText() {
      return this.isConfidential ? 'Turn Off' : 'Turn On';
    },
    updateConfidentialBool() {
      return !this.isConfidential;
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
      @click.prevent="updateConfidentialAttribute(updateConfidentialBool)"
    >
      {{ toggleButtonText }}
    </button>
  </div>
</template>
