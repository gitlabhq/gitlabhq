<script>
import { GlLink } from '@gitlab/ui';
import eventHub from '../event_hub';

export default {
  components: {
    GlLink,
  },
  inject: {
    displayText: {
      default: '',
    },
  },
  props: {
    openModal: {
      type: String,
      required: true,
    },
  },
  methods: {
    showModal() {
      eventHub.$emit(this.openModal);
    },
  },
};
</script>

<template>
  <gl-link data-is-link="true" data-testid="revert-commit-link" @click="showModal">
    {{ displayText }}
  </gl-link>
</template>
