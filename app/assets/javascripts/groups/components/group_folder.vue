<script>
export default {
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="list-group">
    <group-item v-for="group in groups" :group="group" />
  </ul>
</template>
