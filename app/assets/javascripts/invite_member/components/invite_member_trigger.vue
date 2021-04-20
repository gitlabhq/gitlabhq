<script>
import { GlLink } from '@gitlab/ui';
import { OPEN_MODAL } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlLink,
  },
  props: {
    displayText: {
      type: String,
      required: false,
      default: '',
    },
    event: {
      type: String,
      required: false,
      default: '',
    },
    label: {
      type: String,
      required: false,
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
