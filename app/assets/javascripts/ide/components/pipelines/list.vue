<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import _ from 'underscore';
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
          linkStart: `<a href="${_.escape(this.currentProject.web_url)}/-/ci/lint">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    showLoadingIcon() {
      return this.isLoadingPipeline && this.latestPipeline === null;
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
      v-if="showLoadingIcon"
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
            {{ __('Pipeline') }}
          </strong>
          <a
            :href="latestPipeline.path"
            target="_blank"
            class="ide-external-link"
          >
            #{{ latestPipeline.id }}
            <icon
              :size="12"
              name="external-link"
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
          {{ __('Found errors in your .gitlab-ci.yml:') }}
        </p>
        <p class="append-bottom-0 break-word">
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
            {{ __('Jobs') }}
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
            {{ __('Failed Jobs') }}
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
