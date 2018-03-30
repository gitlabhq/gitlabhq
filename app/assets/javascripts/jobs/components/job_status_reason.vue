<script>
export default {
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div
    class="bs-callout bs-callout-danger"
    role="alert"
    aria-live="assertive"
  >
    {{ job.status.callout_message }}
  </div>
</template>
