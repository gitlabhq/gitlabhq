<script>
import RadioFilter from '../shared/radio_filter.vue';
import { statusFilterData } from './data';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  statusFilterData,
};
</script>

<template>
  <radio-filter :filter-data="$options.statusFilterData" />
</template>
