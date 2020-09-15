<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    refPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div data-testid="issue-title">
    <p class="gl-font-weight-bold">{{ title }}</p>
    <p class="gl-mb-0">{{ refPath }}</p>
  </div>
</template>
