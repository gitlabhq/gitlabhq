<script>
export default {
  props: {
    mergeRequestsIllustrationPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <router-view :merge-requests-illustration-path="mergeRequestsIllustrationPath" />
</template>
