<script>
import { mapState } from 'vuex';
import { confidentialFilterData } from '../constants/confidential_filter_data';
import { HR_DEFAULT_CLASSES } from '../constants';
import RadioFilter from './radio_filter.vue';

export default {
  name: 'ConfidentialityFilter',
  components: {
    RadioFilter,
  },
  computed: {
    ...mapState(['useNewNavigation']),
  },
  confidentialFilterData,
  HR_DEFAULT_CLASSES,
};
</script>

<template>
  <div>
    <radio-filter class="gl-px-5" :filter-data="$options.confidentialFilterData" />
    <hr v-if="!useNewNavigation" :class="$options.HR_DEFAULT_CLASSES" />
  </div>
</template>
