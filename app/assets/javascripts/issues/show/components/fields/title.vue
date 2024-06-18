<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import updateMixin from '../../mixins/update';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
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
  <gl-form-group
    :label="__('Title')"
    label-for="issuable-title"
    label-class="gl-sr-only"
    class="gl-mb-0"
  >
    <gl-form-input
      id="issuable-title"
      ref="input"
      :value="value"
      class="form-control"
      dir="auto"
      type="text"
      :placeholder="__('Title')"
      :aria-label="__('Title')"
      @input="(val) => $emit('input', val)"
      @keydown.meta.enter.native="updateIssuable"
      @keydown.ctrl.enter.native="updateIssuable"
    />
  </gl-form-group>
</template>
