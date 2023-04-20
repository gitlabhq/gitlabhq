<script>
import { mapState } from 'vuex';
import { stateFilterData } from '../constants/state_filter_data';
import { HR_DEFAULT_CLASSES } from '../constants';
import RadioFilter from './radio_filter.vue';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  computed: {
    ...mapState(['useNewNavigation']),
  },
  stateFilterData,
  HR_DEFAULT_CLASSES,
};
</script>

<template>
  <div>
    <radio-filter class="gl-px-5" :filter-data="$options.stateFilterData" />
    <hr v-if="!useNewNavigation" :class="$options.HR_DEFAULT_CLASSES" />
  </div>
</template>
