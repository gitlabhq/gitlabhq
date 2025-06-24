<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    headerText: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    toggleText() {
      const selected = this.items.find((option) => option.value === this.value);
      return selected?.text || this.headerText;
    },
  },
  methods: {
    reset() {
      this.$emit('input', undefined);
      this.$refs.listbox.close?.();
    },
  },
};
</script>

<template>
  <gl-form-group :label="label">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="headerText"
      is-check-centered
      :items="items"
      :reset-button-label="__('Reset')"
      :selected="value"
      :toggle-text="toggleText"
      @reset="reset"
      @select="$emit('input', $event)"
    />
  </gl-form-group>
</template>
