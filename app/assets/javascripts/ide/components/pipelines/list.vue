<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import JobsList from '../jobs/list.vue';

export default {
  components: {
    LoadingIcon,
    Icon,
    CiIcon,
    Tabs,
    Tab,
    JobsList,
  },
  computed: {
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount', 'failedStages', 'pipelineFailed']),
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
  <div class="ide-pipeline">
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
            class="ide-external-link"
          >
            #{{ latestPipeline.id }}
            <icon
              name="external-link"
              :size="12"
            />
          </a>
        </span>
      </header>
      <tabs class="ide-pipeline-list">
        <tab
          :active="!pipelineFailed"
        >
          <template slot="title">
            Jobs
            <span
              v-if="jobsCount"
              class="badge badge-pill"
            >
              {{ jobsCount }}
            </span>
          </template>
          <jobs-list
            :loading="isLoadingJobs"
            :stages="stages"
          />
        </tab>
        <tab
          :active="pipelineFailed"
        >
          <template slot="title">
            Failed Jobs
            <span
              v-if="failedJobsCount"
              class="badge badge-pill"
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

<style scoped>
.ide-pipeline {
  display: flex;
  flex-direction: column;
}

.ide-pipeline-list {
  flex: 1;
  overflow: auto;
}

.ide-pipeline-header {
  min-height: 50px;
  padding-left: 16px;
  padding-right: 16px;
}

.ide-pipeline-header .ci-status-icon {
  display: flex;
}
</style>
