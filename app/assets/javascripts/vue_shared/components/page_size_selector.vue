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
    // Temporary prop to avoid using 100 page size on vulnerability report
    // when some feature flags are enabled to avoid GraphQL complexity issues
    // See https://gitlab.com/gitlab-org/gitlab/-/issues/580593
    excludeLargePageSize: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    availablePageSizes() {
      return this.excludeLargePageSize ? PAGE_SIZES.filter(({ value }) => value < 100) : PAGE_SIZES;
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
