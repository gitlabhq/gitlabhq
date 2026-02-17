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
    excludePageSizes: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    availablePageSizes() {
      return this.excludePageSizes.length > 0
        ? PAGE_SIZES.filter(({ value }) => !this.excludePageSizes.includes(value))
        : PAGE_SIZES;
    },
    selectedItem() {
      return this.availablePageSizes.find(({ value }) => value === this.value);
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
};
</script>

<template>
  <gl-collapsible-listbox
    :toggle-text="toggleText"
    :items="availablePageSizes"
    :selected="value"
    @select="emitInput($event)"
  />
</template>
