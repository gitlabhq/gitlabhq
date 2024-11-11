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
  <gl-card class="gl-h-full" body-class="gl-h-full gl-py-0">
    <template #header>
      <h3 class="gl-m-0 gl-inline-flex gl-items-center gl-gap-2 gl-self-center gl-text-base">
        {{ __('Statistics') }}
      </h3>
    </template>
    <template #default>
      <gl-loading-icon v-if="isLoading" size="md" class="my-3" />
      <template v-else>
        <p
          v-for="statistic in getStatistics(statisticsLabels)"
          :key="statistic.key"
          :class="['js-stats', 'gl-py-4', 'gl-m-0', 'gl-border-b', 'last:gl-border-b-0']"
        >
          {{ statistic.label }}
          <span class="light gl-float-right">{{ statistic.value }}</span>
        </p>
      </template>
    </template>
  </gl-card>
</template>
