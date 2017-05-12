<script>
export default {
  props: {
    groups: {
      type: Object,
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
