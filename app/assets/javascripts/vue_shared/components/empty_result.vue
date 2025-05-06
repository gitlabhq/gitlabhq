<script>
import emptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { GlEmptyState } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export const TYPES = {
  search: 'search',
  filter: 'filter',
};

export default {
  i18n: {
    titleSearch: __('No results found'),
    descriptionSearch: __('Edit your search and try again.'),
    descriptionSearchMinLength: __('Search must be at least %{searchMinimumLength} characters.'),
    titleFilter: __('No results found'),
    descriptionFilter: __('To widen your search, change or remove filters above.'),
  },
  components: {
    GlEmptyState,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: TYPES.search,
      validator: (type) => Object.values(TYPES).includes(type),
    },
    search: {
      type: String,
      required: false,
      default: '',
    },
    searchMinimumLength: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    title() {
      return this.type === TYPES.search
        ? this.$options.i18n.titleSearch
        : this.$options.i18n.titleFilter;
    },
    description() {
      if (this.search.length < this.searchMinimumLength) {
        return sprintf(this.$options.i18n.descriptionSearchMinLength, {
          searchMinimumLength: this.searchMinimumLength,
        });
      }

      return this.type === TYPES.search
        ? this.$options.i18n.descriptionSearch
        : this.$options.i18n.descriptionFilter;
    },
  },
  emptyStateSvgPath,
};
</script>

<template>
  <gl-empty-state
    :svg-path="$options.emptyStateSvgPath"
    :title="title"
    :description="description"
  />
</template>
