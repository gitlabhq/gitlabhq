<script>
import { HR_DEFAULT_CLASSES } from '../../constants';
import RadioFilter from '../radio_filter.vue';
import { statusFilterData } from './data';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  statusFilterData,
  HR_DEFAULT_CLASSES,
};
</script>

<template>
  <radio-filter :filter-data="$options.statusFilterData" />
</template>
