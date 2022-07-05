<script>
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
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
    <h4>{{ __('Statistics') }}</h4>
    <gl-loading-icon v-if="isLoading" size="lg" class="my-3" />
    <template v-else>
      <p v-for="statistic in getStatistics(statisticsLabels)" :key="statistic.key" class="js-stats">
        {{ statistic.label }}
        <span class="light float-right">{{ statistic.value }}</span>
      </p>
    </template>
  </gl-card>
</template>
