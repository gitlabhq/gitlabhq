<script>
export default {
  name: 'GroupMembersApp',
  props: {
    groupId: {
      type: Number,
      required: true,
    },
    currentUserId: {
      type: Number,
      required: false,
      default: null,
    },
    members: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <span>
    <!-- Temporary empty template -->
  </span>
</template>
