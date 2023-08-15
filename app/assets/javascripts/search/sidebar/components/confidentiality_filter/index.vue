<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
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
};
</script>

<template>
  <div>
    <radio-filter :filter-data="$options.confidentialFilterData" />
  </div>
</template>
