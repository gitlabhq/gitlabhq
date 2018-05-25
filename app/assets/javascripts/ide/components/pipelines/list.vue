<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import JobsList from '../jobs/list.vue';

export default {
  components: {
    LoadingIcon,
    CiIcon,
    Tabs,
    Tab,
    JobsList,
  },
  computed: {
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount', 'failedStages']),
    ...mapState('pipelines', ['isLoadingPipeline', 'latestPipeline', 'stages', 'isLoadingJobs']),
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
          :status="latestPipeline.details.status"
          :size="24"
        />
        <span class="prepend-left-8">
          <strong>
            Pipeline
          </strong>
          <a
            :href="latestPipeline.path"
            target="_blank"
          >
            #{{ latestPipeline.id }}
          </a>
        </span>
      </header>
      <tabs>
        <tab active>
          <template slot="title">
            Jobs
            <span
              v-if="jobsCount"
              class="badge"
            >
              {{ jobsCount }}
            </span>
          </template>
          <jobs-list
            :loading="isLoadingJobs"
            :stages="stages"
          />
        </tab>
        <tab>
          <template slot="title">
            Failed Jobs
            <span
              v-if="failedJobsCount"
              class="badge"
            >
              {{ failedJobsCount }}
            </span>
          </template>
          <jobs-list
            :loading="isLoadingJobs"
            :stages="failedStages"
          />
        </tab>
      </tabs>
    </template>
  </div>
</template>

<style>
.ide-pipeline-header .ci-status-icon {
  display: flex;
}
</style>
