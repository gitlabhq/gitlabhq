<script>
export default {
  name: 'CommitListItemDescription',
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
