<script>
import { stateFilterData } from '../constants/state_filter_data';
import RadioFilter from './radio_filter.vue';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  stateFilterData,
};
</script>

<template>
  <div>
    <radio-filter class="gl-px-5" :filter-data="$options.stateFilterData" />
    <hr class="gl-my-5 gl-mx-5 gl-border-gray-100" />
  </div>
</template>
