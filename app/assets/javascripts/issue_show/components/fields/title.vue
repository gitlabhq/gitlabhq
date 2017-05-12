<script>
  export default {
    props: {
      store: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        state: this.store.formState,
      };
    },
  };
</script>

<template>
  <fieldset>
    <label
      class="sr-only"
      for="issue-title">
      Title
    </label>
    <input
      id="issue-title"
      class="form-control"
      type="text"
      placeholder="Issue title"
      aria-label="Issue title"
      v-model="state.title" />
  </fieldset>
</template>
