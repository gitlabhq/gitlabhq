<script>
import ListPresenter from './list.vue';
import TablePresenter from './table.vue';

const DISPLAY_TYPES = {
  LIST: 'list',
  ORDERED_LIST: 'orderedList',
  TABLE: 'table',
};

export default {
  name: 'DataPresenter',
  components: {
    TablePresenter,
    ListPresenter,
  },
  props: {
    displayType: {
      required: true,
      type: String,
    },
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
  },
  DISPLAY_TYPES,
};
</script>
<template>
  <table-presenter
    v-if="displayType === $options.DISPLAY_TYPES.TABLE"
    :data="data"
    :fields="fields"
    :loading="loading"
  />
  <list-presenter
    v-else-if="
      displayType === $options.DISPLAY_TYPES.LIST ||
      displayType === $options.DISPLAY_TYPES.ORDERED_LIST
    "
    :data="data"
    :fields="fields"
    :loading="loading"
    :list-type="displayType === $options.DISPLAY_TYPES.LIST ? 'ul' : 'ol'"
  />
</template>
