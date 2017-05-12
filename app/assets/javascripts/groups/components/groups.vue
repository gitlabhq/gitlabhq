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
  <div>
    <group-folder :groups="groups" />
  </div>
</template>
