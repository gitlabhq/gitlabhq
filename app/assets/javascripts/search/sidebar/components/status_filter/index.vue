<script>
import { __ } from '~/locale';
import {
  SCOPE_ISSUES,
  SCOPE_MERGE_REQUESTS,
  STATE_FILTER_PARAM,
  STATE_FILTERS,
} from '~/search/sidebar/constants';
import RadioFilter from '../shared/radio_filter.vue';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  i18n: {
    header: __('Status'),
  },
  computed: {
    filtersArray() {
      return {
        [SCOPE_ISSUES]: [STATE_FILTERS.ANY, STATE_FILTERS.OPEN, STATE_FILTERS.CLOSED],
        [SCOPE_MERGE_REQUESTS]: [
          STATE_FILTERS.ANY,
          STATE_FILTERS.OPEN,
          STATE_FILTERS.MERGED,
          STATE_FILTERS.CLOSED,
        ],
      };
    },
  },
  STATE_FILTER_PARAM,
};
</script>

<template>
  <radio-filter
    :filters-array="filtersArray"
    :header="$options.i18n.header"
    :filter-param="$options.STATE_FILTER_PARAM"
  />
</template>
