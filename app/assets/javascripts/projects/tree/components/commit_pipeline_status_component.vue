<script>
  import Visibility from 'visibilityjs';
  import ciIcon from '~/vue_shared/components/ci_icon.vue';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';
  import Poll from '~/lib/utils/poll';
  import Flash from '~/flash';
  import { s__, sprintf } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import CommitPipelineService from '../services/commit_pipeline_service';

  export default {
    directives: {
      tooltip,
    },
    components: {
      ciIcon,
      loadingIcon,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      /* This prop can be used to replace some of the `render_commit_status`
      used across GitLab, this way we could use this vue component and add a
      realtime status where it makes sense
      realtime: {
        type: Boolean,
        required: false,
        default: true,
      }, */
    },
    data() {
      return {
        ciStatus: {},
        isLoading: true,
      };
    },
    computed: {
      statusTitle() {
        return sprintf(s__('Commits|Commit: %{commitText}'), { commitText: this.ciStatus.text });
      },
    },
    mounted() {
      this.service = new CommitPipelineService(this.endpoint);
      this.initPolling();
    },
    methods: {
      successCallback(res) {
        const pipelines = res.data.pipelines;
        if (pipelines.length > 0) {
          // The pipeline entity always keeps the latest pipeline info on the `details.status`
          this.ciStatus = pipelines[0].details.status;
        }
        this.isLoading = false;
      },
      errorCallback() {
        this.ciStatus = {
          text: 'not found',
          icon: 'status_notfound',
          group: 'notfound',
        };
        this.isLoading = false;
        Flash(s__('Something went wrong on our end'));
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
  <div>
    <loading-icon
      label="Loading pipeline status"
      size="3"
      v-if="isLoading"
    />
    <a
      v-else
      :href="ciStatus.details_path"
    >
      <ci-icon
        v-tooltip
        :title="statusTitle"
        :aria-label="statusTitle"
        data-container="body"
        :status="ciStatus"
      />
    </a>
  </div>
</template>
