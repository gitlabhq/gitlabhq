<script>
export default {
  props: {
    groups: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasGroups() {
      return Object.keys(this.groups).length > 0;
    },
  },
};
</script>

<template>
  <ul class="content-list group-list-tree" v-show="hasGroups">
    <group-item v-for="(group, index) in groups" :key="index" :group="group" />
  </ul>
</template>
