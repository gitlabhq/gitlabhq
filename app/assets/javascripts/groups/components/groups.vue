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
  <div>
    <group-folder :groups="groups" />
  </div>
</template>
