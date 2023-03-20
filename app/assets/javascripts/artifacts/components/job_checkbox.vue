<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  name: 'JobCheckbox',
  components: {
    GlFormCheckbox,
  },
  props: {
    hasArtifacts: {
      type: Boolean,
      required: true,
    },
    selectedArtifacts: {
      type: Array,
      required: true,
    },
    unselectedArtifacts: {
      type: Array,
      required: true,
    },
  },
  computed: {
    disabled() {
      return !this.hasArtifacts;
    },
    checked() {
      return this.hasArtifacts && this.unselectedArtifacts.length === 0;
    },
    indeterminate() {
      return this.selectedArtifacts.length > 0 && this.unselectedArtifacts.length > 0;
    },
  },
  methods: {
    handleInput(checked) {
      if (checked) {
        this.unselectedArtifacts.forEach((node) => this.$emit('selectArtifact', node, true));
      } else {
        this.selectedArtifacts.forEach((node) => this.$emit('selectArtifact', node, false));
      }
    },
  },
};
</script>
<template>
  <gl-form-checkbox
    :disabled="disabled"
    :checked="checked"
    :indeterminate="indeterminate"
    @input="handleInput"
  />
</template>
