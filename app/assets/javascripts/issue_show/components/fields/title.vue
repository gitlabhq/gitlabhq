<script>
  export default {
    props: {
      formState: {
        type: Object,
        required: true,
      },
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
      v-model="formState.title" />
  </fieldset>
</template>
