<!-- eslint-disable vue/multi-word-component-names -->
<script>
import updateMixin from '../../mixins/update';

export default {
  mixins: [updateMixin],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <fieldset>
    <label class="sr-only" for="issuable-title">{{ __('Title') }}</label>
    <input
      id="issuable-title"
      ref="input"
      :value="value"
      class="form-control gl-border-gray-200"
      dir="auto"
      type="text"
      :placeholder="__('Title')"
      :aria-label="__('Title')"
      @input="$emit('input', $event.target.value)"
      @keydown.meta.enter="updateIssuable"
      @keydown.ctrl.enter="updateIssuable"
    />
  </fieldset>
</template>
