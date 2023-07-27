<script>
import { mapState } from 'vuex';
import { HR_DEFAULT_CLASSES } from '../../constants';
import RadioFilter from '../radio_filter.vue';
import { confidentialFilterData } from './data';

export default {
  name: 'ConfidentialityFilter',
  components: {
    RadioFilter,
  },
  computed: {
    ...mapState(['useSidebarNavigation']),
  },
  confidentialFilterData,
  HR_DEFAULT_CLASSES,
};
</script>

<template>
  <div>
    <radio-filter :filter-data="$options.confidentialFilterData" />
  </div>
</template>
