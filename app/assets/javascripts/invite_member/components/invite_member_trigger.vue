<script>
import { GlLink } from '@gitlab/ui';
import { OPEN_MODAL } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlLink,
  },
  inject: {
    displayText: {
      default: '',
    },
    event: {
      default: '',
    },
    label: {
      default: '',
    },
  },
  methods: {
    openModal() {
      eventHub.$emit(OPEN_MODAL);
    },
  },
};
</script>

<template>
  <gl-link
    data-is-link="true"
    :data-track-event="event"
    :data-track-label="label"
    @click="openModal"
    >{{ displayText }}
  </gl-link>
</template>
