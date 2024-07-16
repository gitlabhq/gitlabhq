<script>
import { GlEmptyState } from '@gitlab/ui';
import emptySearchSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { __ } from '~/locale';

export default {
  i18n: {
    title: __('No results found'),
    description: __('Edit your criteria and try again.'),
  },
  components: { GlEmptyState },
  props: {
    svgPath: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    search: {
      type: String,
      required: true,
    },
  },
  computed: {
    glEmptyStateProps() {
      const baseProps = {
        svgHeight: 144,
      };

      if (this.search !== '') {
        return {
          ...baseProps,
          svgPath: emptySearchSvgPath,
          title: this.$options.i18n.title,
          description: this.$options.i18n.description,
        };
      }

      return {
        ...baseProps,
        svgPath: this.svgPath,
        title: this.title,
        description: this.description,
      };
    },
  },
};
</script>

<template>
  <gl-empty-state v-bind="glEmptyStateProps">
    <template #actions>
      <slot name="actions"></slot>
    </template>
  </gl-empty-state>
</template>
