<script>
import { mapActions, mapState } from 'vuex';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  components: {
    LoadingIcon,
    CiIcon,
  },
  computed: {
    ...mapState('pipelines', ['isLoadingPipeline', 'latestPipeline']),
    statusIcon() {
      return {
        group: this.latestPipeline.status,
        icon: `status_${this.latestPipeline.status}`,
      };
    },
  },
  mounted() {
    this.fetchLatestPipeline();
  },
  methods: {
    ...mapActions('pipelines', ['fetchLatestPipeline']),
  },
};
</script>

<template>
  <div>
    <loading-icon
      v-if="isLoadingPipeline"
      class="prepend-top-default"
      size="2"
    />
    <template v-else-if="latestPipeline">
      <ci-icon
        :status="statusIcon"
      />
      #{{ latestPipeline.id }}
    </template>
  </div>
</template>

<style>
</style>
