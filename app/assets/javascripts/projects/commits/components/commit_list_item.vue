<script>
export default {
  name: 'CommitItem',
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    {{ commit.message }}
  </div>
</template>
