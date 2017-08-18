<script>
export default {
  props: {
    groups: {
      type: Object,
      required: true,
    },
    baseGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <ul class="content-list group-list-tree">
    <group-item
      v-for="(group, index) in groups"
      :key="index"
      :group="group"
      :base-group="baseGroup"
      :collection="groups"
    />
  </ul>
</template>
