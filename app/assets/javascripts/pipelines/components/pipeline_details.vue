
<script>
  import Visibility from 'visibilityjs';
  import Poll from '../../lib/utils/poll';
  import PipelineStore from '../stores/pipeline_store';
  import PipelineService from '../services/pipeline_service';
  import pipelineGraph from './graph/graph_component.vue';
  import pipelineInfoBlock from './pipeline_info_block.vue';
  import pipelineCommitBlock from './pipeline_commit_block.vue';
  import ciHeader from '../../vue_shared/components/header_ci_component.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import eventHub from '../event_hub';
  import { tabs, tab } from '../../vue_shared/components/tabs';

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
      loadingIcon,
      pipelineGraph,
      pipelineCommitBlock,
      pipelineInfoBlock,
      tabs,
      tab
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
        isLoadingJobTrace: false,
        //move to store
        jobLog: null,
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
        // open job tab
        this.jobTab = job;

        this.$nextTick(() => {
          this.selectedTab = 3;
        });

        // let's load the data!
        this.service.getJobTrace(job.status.details_path)
          //.then(response => response.json())
          .then((resp) => {
            this.jobLog = resp.bodyText;
          });

      },

      closeJobTab() {
        this.jobTab = null;

        this.$nextTick(() => {
          this.selectedTab = 0;
        });
      },

      getJobTabTitle() {
        return `<a> status icon - ${this.jobTab.name}</a>`;
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
        @tabSelected="handleSelectedTab()"
        @closeTab="closeJobTab()"
        :default-index="selectedTab"
        css-class="pipelines-tabs no-top no-bottom">

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
          {{jobLog}}
        </tab>
      </tabs>

    </template>
  </div>
</template>
