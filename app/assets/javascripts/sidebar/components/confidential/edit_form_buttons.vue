<script>
import $ from 'jquery';
import eventHub from '../../event_hub';

export default {
  props: {
    isConfidential: {
      required: true,
      type: Boolean,
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
  methods: {
    closeForm() {
      eventHub.$emit('closeConfidentialityForm');
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    submitForm() {
      this.closeForm();
      this.updateConfidentialAttribute(this.updateConfidentialBool);
    },
  },
};
</script>

<template>
  <div class="sidebar-item-warning-message-actions">
    <button
      type="button"
      class="btn btn-default append-right-10"
      @click="closeForm"
    >
      {{ __('Cancel') }}
    </button>
    <button
      type="button"
      class="btn btn-close"
      @click.prevent="submitForm"
    >
      {{ toggleButtonText }}
    </button>
  </div>
</template>
