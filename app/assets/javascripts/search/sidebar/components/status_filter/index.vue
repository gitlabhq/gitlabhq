<script>
import { mapState } from 'vuex';
import { HR_DEFAULT_CLASSES } from '../../constants';
import RadioFilter from '../radio_filter.vue';
import { statusFilterData } from './data';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  computed: {
    ...mapState(['useNewNavigation']),
  },
  statusFilterData,
  HR_DEFAULT_CLASSES,
};
</script>

<template>
  <div>
    <radio-filter :filter-data="$options.statusFilterData" />
  </div>
</template>
