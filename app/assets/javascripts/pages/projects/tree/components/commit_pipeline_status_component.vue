<script>
  import Visibility from 'visibilityjs';
  import ciIcon from '~/vue_shared/components/ci_icon.vue';
  import Poll from '~/lib/utils/poll';
  import Flash from '~/flash';
  import tooltip from '~/vue_shared/directives/tooltip';
  import CommitPipelineService from '../services/commit_pipeline_service';

  export default {
    directives: {
      tooltip,
    },
    components: {
      ciIcon,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        ciStatus: {},
        isLoading: true,
        service: {},
      };
    },
    mounted() {
      this.service = new CommitPipelineService(this.endpoint);
      this.initPolling();
    },
    methods: {
      successCallback(res) {
        if (res.data.pipelines.length > 0) {
          this.ciStatus = res.data.pipelines[0].details.status;
          this.isLoading = false;
        } else {
          this.isLoading = true;
        }
      },
      errorCallback(err) {
        Flash(err);
      },
      initPolling() {
        this.poll = new Poll({
          resource: this.service,
          method: 'fetchData',
          successCallback: response => this.successCallback(response),
          errorCallback: this.errorCallback,
        });

        if (!Visibility.hidden()) {
          this.isLoading = true;
          this.poll.makeRequest();
        } else {
          this.fetchPipelineCommitData();
        }

        Visibility.change(() => {
          if (!Visibility.hidden()) {
            this.poll.restart();
          } else {
            this.poll.stop();
          }
        });
      },
      fetchPipelineCommitData() {
        this.service.fetchData()
        .then(this.successCallback)
        .catch(this.errorCallback);
      },
    },
    destroy() {
      this.poll.stop();
    },
  };
</script>
<template>
  <div
  v-if="isLoading">
  </div>
  <a
    v-else
    :href="ciStatus.details_path"
  >
    <ci-icon
      v-tooltip
      :title="ciStatus.text"
      :aria-label="ciStatus.text"
      data-container="body"
      :status="ciStatus"
    />
  </a>
</template>
