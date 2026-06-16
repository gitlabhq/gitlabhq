<script>
import { GlSorting } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'WorkItemDisplaySettingsSort',
  components: {
    GlSorting,
  },
  i18n: {
    sortByLabel: __('Sort by'),
  },
  props: {
    sortOptions: {
      type: Array,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
    },
  },
  emits: ['sort'],
  computed: {
    transformedSortOptions() {
      return this.sortOptions.map(({ id, title }) => ({ value: id, text: title }));
    },
    selectedOption() {
      return this.sortOptions.find(
        ({ sortDirection }) =>
          sortDirection.ascending === this.sortKey || sortDirection.descending === this.sortKey,
      );
    },
    sortById() {
      return this.selectedOption?.id ?? null;
    },
    isAscending() {
      return this.selectedOption?.sortDirection.ascending === this.sortKey;
    },
  },
  methods: {
    onSortByChange(id) {
      const option = this.sortOptions.find((opt) => opt.id === id);
      if (!option) return;
      const newKey = this.isAscending
        ? option.sortDirection.ascending
        : option.sortDirection.descending;
      this.$emit('sort', newKey);
    },
    onSortDirectionChange(isAscending) {
      if (!this.selectedOption) return;
      const newKey = isAscending
        ? this.selectedOption.sortDirection.ascending
        : this.selectedOption.sortDirection.descending;
      this.$emit('sort', newKey);
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-items-center gl-justify-between gl-gap-3"
    data-testid="display-settings-sort"
  >
    <span>{{ $options.i18n.sortByLabel }}</span>
    <!-- eslint-disable vue/v-on-event-hyphenation -->
    <gl-sorting
      :sort-options="transformedSortOptions"
      :sort-by="sortById"
      :is-ascending="isAscending"
      @sortByChange="onSortByChange"
      @sortDirectionChange="onSortDirectionChange"
    />
    <!-- eslint-enable vue/v-on-event-hyphenation -->
  </div>
</template>
