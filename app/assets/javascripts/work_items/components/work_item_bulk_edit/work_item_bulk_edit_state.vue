<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  listboxItems: [
    { text: __('Open'), value: 'reopen' },
    { text: __('Closed'), value: 'close' },
  ],
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    toggleText() {
      const selected = this.$options.listboxItems.find((option) => option.value === this.value);
      return selected?.text || __('Select state');
    },
  },
  methods: {
    reset() {
      this.$emit('input', undefined);
      this.$refs.listbox.close();
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('State')">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="__('Select state')"
      is-check-centered
      :items="$options.listboxItems"
      :reset-button-label="__('Reset')"
      :selected="value"
      :toggle-text="toggleText"
      @reset="reset"
      @select="$emit('input', $event)"
    />
  </gl-form-group>
</template>
