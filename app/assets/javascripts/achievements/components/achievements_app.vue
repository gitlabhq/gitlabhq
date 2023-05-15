<script>
export default {
  inject: {
    canAdminAchievement: {
      type: Boolean,
      required: true,
    },
    canAwardAchievement: {
      type: Boolean,
      required: true,
    },
    groupFullPath: {
      type: String,
      required: true,
    },
    groupId: {
      type: Number,
      required: true,
    },
    textQuery: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div></div>
</template>
