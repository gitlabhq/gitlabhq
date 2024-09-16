<script>
import RadioFilter from '../shared/radio_filter.vue';
import { confidentialFilterData } from './data';

export default {
  name: 'ConfidentialityFilter',
  components: {
    RadioFilter,
  },
  confidentialFilterData,
};
</script>

<template>
  <div>
    <radio-filter :filter-data="$options.confidentialFilterData" />
  </div>
</template>
