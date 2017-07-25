
<script>
  import Visibility from 'visibilityjs';
  import Anser from 'anser';
  import Poll from '../../lib/utils/poll';
  import PipelineStore from '../stores/pipeline_store';
  import PipelineService from '../services/pipeline_service';
  import pipelineGraph from './graph/graph_component.vue';
  import pipelineInfoBlock from './pipeline_info_block.vue';
  import pipelineCommitBlock from './pipeline_commit_block.vue';
  import ciHeader from '../../vue_shared/components/header_ci_component.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import jobLog from './job_log.vue';
  import { tabs, tab } from '../../vue_shared/components/tabs';
  import eventHub from '../event_hub';

  export default {
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      cssClass: {
        type: String,
        required: false,
        default: '',
      },
    },
    components: {
      ciHeader,
      jobLog,
      loadingIcon,
      pipelineGraph,
      pipelineCommitBlock,
      pipelineInfoBlock,
      tabs,
      tab,
    },
    data() {
      const store = new PipelineStore();
      const service = new PipelineService(this.endpoint);

      return {
        store,
        service,
        state: store.state,
        actions: this.getActions(),
        isLoading: false,
        jobTab: null,
        selectedTab: 0,
        isLoadingJob: false,
      };
    },
    created() {
      this.poll = new Poll({
        resource: this.service,
        method: 'getPipeline',
        successCallback: this.successCallback.bind(this),
        errorCallback: this.errorCallback.bind(this),
      });

      if (!Visibility.hidden()) {
        this.isLoading = true;
        this.poll.makeRequest();
      } else {
        this.refreshPipeline();
      }

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          this.poll.restart();
        } else {
          this.poll.stop();
        }
      });

      eventHub.$on('jobNodeClicked', this.openJob);

      // Check for open tab url
      const jobId = gl.utils.getParameterByName('job');
      if (jobId) {
        // look for the job in the data we have and load it
      }
    },
    beforeDestroy() {
      eventHub.$off('jobNodeClicked', this.openJob);
    },
    computed: {
      status() {
        return this.state.pipeline.details && this.state.pipeline.details.status;
      },
    },
    methods: {
      successCallback(response) {
        return response.json().then((data) => {
          this.isLoading = false;
          this.store.storePipeline(data);
        });
      },

      errorCallback () {
        this.state.isLoading = false;
        return new Flash('An error occurred while fetching the pipeline.');
      },

      refreshPipeline() {
        this.service.getPipeline()
          .then(response => this.successCallback(response))
          .catch(() => this.errorCallback());
      },

      getActions() {
        const actions = [];

        if (this.state && this.state.pipeline.retry_path) {
          actions.push({
            label: 'Retry',
            path: this.state.pipeline.retry_path,
            cssClass: 'js-retry-button btn btn-inverted-secondary',
            type: 'button',
            isLoading: false,
          });
        }

        if (this.state && this.state.pipeline.cancel_path) {
          actions.push({
            label: 'Cancel running',
            path: this.state.pipeline.cancel_path,
            cssClass: 'js-btn-cancel-pipeline btn btn-danger',
            type: 'button',
            isLoading: false,
          });
        }

        return actions;
      },

      postAction(action) {
        const index = this.actions.indexOf(action);

        this.$set(this.actions[index], 'isLoading', true);

        this.service.postAction(action.path)
          .then(() => this.refreshPipeline())
          .catch(() => new Flash('An error occurred while making the request.'));

      },

      openJob(job) {
        const jobId = job.jobs[0].id
        // 1. Update URL
        this.updateUrl(jobId);

        // 2. Check if there is an open job tab and if it is not the same
        if (!this.jobTab || this.jobTab.jobs[0].id !== jobId) {
          // 2. Open Job Tab
          this.jobTab = job;

          this.$nextTick(() => {
            this.selectedTab = 3;
          });

          const endpoint = job.status.details_path;
          this.isLoadingJob = true;

          // 3. Load Job data
          this.service.getJobData(endpoint)
            .then(resp => resp.json())
            .then(data => this.store.storeJob(data))
            .then(() => {
              return this.service.getJobLog(endpoint)
                //.then(response => response.json())
                .then((resp) => {
                  const log = Anser.ansiToHtml(resp.bodyText, {use_classes: true});
                  const linkedLog = Anser.linkify(log);

                  this.store.storeLog(linkedLog.split('\n'));
                })
            })
            .then(() => {
              this.isLoadingJob = false;
            })
            .catch(() => {
              this.isLoadingJob = false;
              Flash('An error occurred while fetching the job log.')
            });

        } else if (this.jobTab.jobs[0].id === jobId) {
          this.selectedTab = 3;
        }
      },

      closeJobTab() {
        this.jobTab = null;

        this.$nextTick(() => {
          this.selectedTab = 0;
        });
      },

      getJobTabTitle() {
        return `<a> status icon - ${this.jobTab.name}</a>`;
      },

      updateUrl(jobId) {
        const url = `?job=${jobId}`;
        window.history.pushState(null, null, url);
      }
    },
  };
</script>
<template>
  <div :class="cssClass">
    <loading-icon v-if="isLoading" size="3" />

    <template v-else>
      <div class="pipeline-header-container">
        <ci-header
          :status="status"
          item-name="Pipeline"
          :item-id="state.pipeline.id"
          :time="state.pipeline.created_at"
          :user="state.pipeline.user"
          :actions="actions"
          @actionClicked="postAction"
          />
      </div>

      <pipeline-commit-block
        v-if="state.pipeline.commit"
        :commit="state.pipeline.commit"
        />

      <pipeline-info-block :pipeline="state.pipeline" />

      <tabs
        class="tabs-holder"
        @closeTab="closeJobTab()"
        :default-index="selectedTab"
        container-class="pipelines-tabs no-top no-bottom">

        <tab title="Pipeline" random-prop="foo">
          <pipeline-graph :pipeline="state.pipeline" />
        </tab>

        <tab title="Jobs <badge goes here>">
          TO BE DONE - JOBS TABLE
        </tab>

        <tab title="Failed Jobs <badge goes here>">
          TO BE DONE - FAILED JOBS
        </tab>

        <tab
          v-if="jobTab"
          :title="jobTab.name"
          :is-closable="true">

          <job-log
            class="job-log-container"
            v-if="state.log"
            :log="state.log"
            />
        </tab>
      </tabs>

    </template>
  </div>
</template>
