<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { sprintf, __ } from '../../../locale';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import EmptyState from '../../../pipelines/components/empty_state.vue';
import JobsList from '../jobs/list.vue';

export default {
  components: {
    LoadingIcon,
    Icon,
    CiIcon,
    Tabs,
    Tab,
    JobsList,
    EmptyState,
  },
  computed: {
    ...mapState(['pipelinesEmptyStateSvgPath', 'links']),
    ...mapGetters(['currentProject']),
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount', 'failedStages', 'pipelineFailed']),
    ...mapState('pipelines', ['isLoadingPipeline', 'latestPipeline', 'stages', 'isLoadingJobs']),
    ciLintText() {
      return sprintf(
        __('You can also test your .gitlab-ci.yml in the %{linkStart}Lint%{linkEnd}'),
        {
          linkStart: `<a href="${this.currentProject.web_url}/-/ci/lint">`,
          linkEnd: '</a>',
        },
        false,
      );
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
  <div class="ide-pipeline">
    <loading-icon
      v-if="isLoadingPipeline && latestPipeline === null"
      class="prepend-top-default"
      size="2"
    />
    <template v-else-if="latestPipeline !== null">
      <header
        v-if="latestPipeline"
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
      <empty-state
        v-if="latestPipeline === false"
        :help-page-path="links.ciHelpPagePath"
        :empty-state-svg-path="pipelinesEmptyStateSvgPath"
        :can-set-ci="true"
      />
      <div
        v-else-if="latestPipeline.yamlError"
        class="bs-callout bs-callout-danger"
      >
        <p class="append-bottom-0">
          Found errors in your .gitlab-ci.yml:
        </p>
        <p class="append-bottom-0">
          {{ latestPipeline.yamlError }}
        </p>
        <p
          class="append-bottom-0"
          v-html="ciLintText"
        ></p>
      </div>
      <tabs
        v-else
        class="ide-pipeline-list"
      >
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
  height: 100%;
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

.ide-pipeline .empty-state {
  margin-top: auto;
  margin-bottom: auto;
}
</style>
