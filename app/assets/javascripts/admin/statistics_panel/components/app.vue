<script>
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import statisticsLabels from '../constants';

export default {
  components: {
    GlCard,
    GlLoadingIcon,
  },
  data() {
    return {
      statisticsLabels,
    };
  },
  computed: {
    ...mapState(['isLoading', 'statistics']),
    ...mapGetters(['getStatistics']),
  },
  mounted() {
    this.fetchStatistics();
  },
  methods: {
    ...mapActions(['fetchStatistics']),
  },
};
</script>

<template>
  <gl-card>
    <h4 class="gl-heading-4">{{ __('Statistics') }}</h4>
    <slot name="footer">
      <gl-loading-icon v-if="isLoading" size="lg" class="my-3" />
      <template v-else>
        <p
          v-for="statistic in getStatistics(statisticsLabels)"
          :key="statistic.key"
          class="js-stats"
        >
          {{ statistic.label }}
          <span class="light gl-float-right">{{ statistic.value }}</span>
        </p>
      </template>
    </slot>
  </gl-card>
</template>
