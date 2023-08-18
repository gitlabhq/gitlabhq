<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { n__ } from '~/locale';

export const PAGE_SIZES = [20, 50, 100].map((value) => ({
  value,
  text: n__('SecurityReports|Show %d item', 'SecurityReports|Show %d items', value),
}));

export default {
  components: { GlCollapsibleListbox },
  props: {
    value: {
      type: Number,
      required: true,
    },
  },
  computed: {
    selectedItem() {
      return PAGE_SIZES.find(({ value }) => value === this.value);
    },
    toggleText() {
      return this.selectedItem.text;
    },
  },
  methods: {
    emitInput(pageSize) {
      this.$emit('input', pageSize);
    },
  },
  PAGE_SIZES,
};
</script>

<template>
  <gl-collapsible-listbox
    :toggle-text="toggleText"
    :items="$options.PAGE_SIZES"
    :selected="value"
    @select="emitInput($event)"
  />
</template>
