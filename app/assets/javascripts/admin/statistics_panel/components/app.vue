<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import statisticsLabels from '../constants';

export default {
  components: {
    CrudComponent,
  },
  data() {
    return {
      statisticsLabels,
    };
  },
  computed: {
    ...mapState(['isLoading']),
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
  <crud-component
    :is-loading="isLoading"
    :title="__('Statistics')"
    :body-class="{ '!gl-mt-0': !isLoading }"
  >
    <p
      v-for="statistic in getStatistics(statisticsLabels)"
      :key="statistic.key"
      :class="['js-stats', 'gl-py-4', 'gl-m-0', 'gl-border-b', 'last:gl-border-b-0']"
    >
      {{ statistic.label }}
      <span class="light gl-float-right">{{ statistic.value }}</span>
    </p>
  </crud-component>
</template>
