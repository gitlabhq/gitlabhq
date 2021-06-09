<script>
import eventHub, { EVENT_RESPONSIVE_TOGGLE } from '../event_hub';

const TEMPORARY_PLACEHOLDER = 'Placeholder for responsive top nav';

export default {
  props: {
    navData: {
      type: Object,
      required: true,
    },
  },
  created() {
    eventHub.$on(EVENT_RESPONSIVE_TOGGLE, this.onToggle);
  },
  beforeDestroy() {
    eventHub.$off(EVENT_RESPONSIVE_TOGGLE, this.onToggle);
  },
  methods: {
    onToggle() {
      document.body.classList.toggle('top-nav-responsive-open');
    },
  },
  TEMPORARY_PLACEHOLDER,
};
</script>

<template>
  <p>{{ $options.TEMPORARY_PLACEHOLDER }}</p>
</template>
