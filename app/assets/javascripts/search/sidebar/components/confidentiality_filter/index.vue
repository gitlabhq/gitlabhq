<script>
import { __ } from '~/locale';
import {
  SCOPE_ISSUES,
  CONFIDENTAL_FILTER_PARAM,
  CONFIDENTIAL_FILTERS,
} from '~/search/sidebar/constants';
import RadioFilter from '../shared/radio_filter.vue';

export default {
  name: 'ConfidentialityFilter',
  components: {
    RadioFilter,
  },
  i18n: {
    header: __('Confidentiality'),
  },
  computed: {
    filtersArray() {
      return {
        [SCOPE_ISSUES]: [
          CONFIDENTIAL_FILTERS.ANY,
          CONFIDENTIAL_FILTERS.CONFIDENTIAL,
          CONFIDENTIAL_FILTERS.NOT_CONFIDENTIAL,
        ],
      };
    },
  },
  CONFIDENTAL_FILTER_PARAM,
};
</script>

<template>
  <div>
    <radio-filter
      :filters-array="filtersArray"
      :header="$options.i18n.header"
      :filter-param="$options.CONFIDENTAL_FILTER_PARAM"
    />
  </div>
</template>
