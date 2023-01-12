<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { stateFilterData } from '../constants/state_filter_data';
import RadioFilter from './radio_filter.vue';

export default {
  name: 'StatusFilter',
  components: {
    RadioFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ffBasedXPadding() {
      return this.glFeatures.searchPageVerticalNav ? 'gl-px-5' : 'gl-px-0';
    },
  },
  stateFilterData,
};
</script>

<template>
  <div>
    <radio-filter :class="ffBasedXPadding" :filter-data="$options.stateFilterData" />
    <hr class="gl-my-5 gl-mx-5 gl-border-gray-100" />
  </div>
</template>
