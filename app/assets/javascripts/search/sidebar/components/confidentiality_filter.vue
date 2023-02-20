<script>
import { confidentialFilterData } from '../constants/confidential_filter_data';
import RadioFilter from './radio_filter.vue';

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
    <radio-filter class="gl-px-5" :filter-data="$options.confidentialFilterData" />
    <hr class="gl-my-5 gl-mx-5 gl-border-gray-100" />
  </div>
</template>
