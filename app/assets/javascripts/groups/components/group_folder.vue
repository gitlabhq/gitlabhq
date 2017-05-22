<script>
export default {
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasGroups() {
      return this.groups.length > 0;
    },
  },
};
</script>

<template>
  <ul class="content-list group-list-tree" v-show="hasGroups">
    <group-item v-for="(group, index) in groups" :key="index" :group="group" />
  </ul>
</template>
