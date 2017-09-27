<template>
  <div class="list-item">
    <slot></slot>
  </div>
</template>

<script>
import eventHub from '../eventhub';

export default {
  props: {
  },
  data() {
    return {
      editing: false,
    };
  },
  methods: {
    toggleEditing() {
      eventHub.$emit('toggle');
    },
  },
};
</script>
