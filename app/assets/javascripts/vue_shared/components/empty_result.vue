<script>
import emptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';

export const TYPES = {
  search: 'search',
  filter: 'filter',
};

export default {
  i18n: {
    titleSearch: __('No results found'),
    descriptionSearch: __('Edit your search and try again.'),
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
  },
  computed: {
    title() {
      return this.type === TYPES.search
        ? this.$options.i18n.titleSearch
        : this.$options.i18n.titleFilter;
    },
    description() {
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
