<script>
import { mapState } from 'vuex';
import { stateFilterData } from '../constants/state_filter_data';
import RadioFilter from './radio_filter.vue';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  computed: {
    ...mapState(['query']),
    showDropdown() {
      return Object.values(stateFilterData.scopes).includes(this.query.scope);
    },
  },
  stateFilterData,
};
</script>

<template>
  <div v-if="showDropdown">
    <radio-filter :filter-data="$options.stateFilterData" />
    <hr class="gl-my-5 gl-border-gray-100" />
  </div>
</template>
