<script>
import { s__ } from '~/locale';
import eventHub from './event_hub';

export default {
  props: {
    hasStatus: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    buttonText() {
      return this.hasStatus ? s__('SetStatusModal|Edit status') : s__('SetStatusModal|Set status');
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal');
    },
  },
};
</script>

<template>
  <button type="button" class="btn menu-item" @click="openModal">{{ buttonText }}</button>
</template>
