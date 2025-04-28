<script>
import { GlButton, GlCard } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { mapActions, mapState } from 'pinia';
import { useAccessTokens } from '../stores/access_tokens';

export default {
  components: {
    GlButton,
    GlCard,
    GlSingleStat,
  },
  computed: {
    ...mapState(useAccessTokens, ['statistics']),
  },
  methods: {
    ...mapActions(useAccessTokens, ['fetchTokens', 'setFilters', 'setPage']),
    handleFilter(filters) {
      this.setFilters(filters);
      this.setPage(1);
      this.fetchTokens();
    },
  },
};
</script>

<template>
  <div class="gl-my-5 gl-grid gl-gap-4 sm:gl-grid-cols-2 lg:gl-grid-cols-4">
    <gl-card v-for="statistic in statistics" :key="statistic.title">
      <gl-single-stat class="!gl-p-0" :title="statistic.title" :value="statistic.value" />
      <gl-button
        class="mt-2"
        :title="statistic.tooltipTitle"
        variant="link"
        @click="handleFilter(statistic.filters)"
      >
        {{ s__('AccessTokens|Filter list') }}
      </gl-button>
    </gl-card>
  </div>
</template>
