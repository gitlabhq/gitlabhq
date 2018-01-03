<script>
  import updateMixin from '../../mixins/update';

  export default {
    mixins: [updateMixin],
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
      for="issuable-title">
      Title
    </label>
    <input
      id="issuable-title"
      class="form-control"
      type="text"
      placeholder="Title"
      aria-label="Title"
      v-model="formState.title"
      @keydown.meta.enter="updateIssuable"
      @keydown.ctrl.enter="updateIssuable" />
  </fieldset>
</template>
