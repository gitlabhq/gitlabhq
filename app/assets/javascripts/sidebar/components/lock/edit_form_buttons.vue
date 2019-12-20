<script>
import $ from 'jquery';
import { __ } from '~/locale';
import eventHub from '../../event_hub';

export default {
  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },

    updateLockedAttribute: {
      required: true,
      type: Function,
    },
  },

  computed: {
    buttonText() {
      return this.isLocked ? __('Unlock') : __('Lock');
    },

    toggleLock() {
      return !this.isLocked;
    },
  },

  methods: {
    closeForm() {
      eventHub.$emit('closeLockForm');
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    submitForm() {
      this.closeForm();
      this.updateLockedAttribute(this.toggleLock);
    },
  },
};
</script>

<template>
  <div class="sidebar-item-warning-message-actions">
    <button type="button" class="btn btn-default append-right-10" @click="closeForm">
      {{ __('Cancel') }}
    </button>

    <button type="button" class="btn btn-close" @click.prevent="submitForm">
      {{ buttonText }}
    </button>
  </div>
</template>
