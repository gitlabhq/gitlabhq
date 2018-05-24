<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import JobsList from './jobs.vue';

export default {
  components: {
    LoadingIcon,
    CiIcon,
    JobsList,
  },
  computed: {
    ...mapGetters(['currentProject']),
    ...mapState('pipelines', ['isLoadingPipeline', 'latestPipeline']),
    statusIcon() {
      return {
        group: this.latestPipeline.status,
        icon: `status_${this.latestPipeline.status}`,
      };
    },
  },
  created() {
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
      v-if="isLoadingPipeline && !latestPipeline"
      class="prepend-top-default"
      size="2"
    />
    <template v-else-if="latestPipeline">
      <header
        class="ide-tree-header ide-pipeline-header"
      >
        <ci-icon
          :status="statusIcon"
          :size="24"
        />
        <span class="prepend-left-8">
          <strong>
            Pipeline
          </strong>
          <a
            :href="currentProject.web_url + '/pipelines/' + latestPipeline.id"
            target="_blank"
          >
            #{{ latestPipeline.id }}
          </a>
        </span>
      </header>
      <jobs-list />
    </template>
  </div>
</template>

<style>
.ide-pipeline-header .ci-status-icon {
  display: flex;
}
</style>
