<script>
export default {
  name: 'KeydownEnterHandler',
  data() {
    return {
      submitted: false,
    };
  },
  methods: {
    handleSubmit() {
      this.submitted = true;
    },
  },
};
</script>

<template>
  <form data-testid="form" @keydown.enter="handleSubmit">
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-if="submitted" data-testid="submitted">Submitted</span>
  </form>
</template>
