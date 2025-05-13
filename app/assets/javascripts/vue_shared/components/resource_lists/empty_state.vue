<script>
import { GlEmptyState } from '@gitlab/ui';
import EmptyResult, { TYPES } from '~/vue_shared/components/empty_result.vue';

export { TYPES };

export default {
  name: 'ResourceListsEmptyState',
  components: {
    GlEmptyState,
    EmptyResult,
  },
  props: {
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
    type: {
      type: String,
      required: false,
      default: TYPES.search,
      validator: (type) => Object.values(TYPES).includes(type),
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    svgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasSearch() {
      return Boolean(this.search);
    },
  },
};
</script>

<template>
  <empty-result
    v-if="hasSearch"
    :search="search"
    :search-minimum-length="searchMinimumLength"
    :type="type"
  />
  <gl-empty-state
    v-else
    content-class="gl-max-w-75"
    :title="title"
    :description="description"
    :svg-path="svgPath"
  >
    <template #description>
      <slot name="description"></slot>
    </template>
    <template #actions>
      <slot name="actions"></slot>
    </template>
  </gl-empty-state>
</template>
