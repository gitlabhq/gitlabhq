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
    <label class="sr-only" for="issuable-title"> Title </label>
    <input
      id="issuable-title"
      ref="input"
      v-model="formState.title"
      class="form-control qa-title-input"
      dir="auto"
      type="text"
      placeholder="Title"
      aria-label="Title"
      @keydown.meta.enter="updateIssuable"
      @keydown.ctrl.enter="updateIssuable"
    />
  </fieldset>
</template>
