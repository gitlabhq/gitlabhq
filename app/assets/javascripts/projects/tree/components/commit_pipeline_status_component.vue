<script>
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import Poll from '~/lib/utils/poll';
import { __, s__, sprintf } from '~/locale';
import ciIcon from '~/vue_shared/components/ci_icon.vue';
import CommitPipelineService from '../services/commit_pipeline_service';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    ciIcon,
    GlLoadingIcon,
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
    };
  },
  computed: {
    statusTitle() {
      return sprintf(s__('PipelineStatusTooltip|Pipeline: %{ciStatus}'), {
        ciStatus: this.ciStatus.text,
      });
    },
  },
  mounted() {
    this.service = new CommitPipelineService(this.endpoint);
    this.initPolling();
  },
  beforeDestroy() {
    this.poll.stop();
  },
  methods: {
    successCallback(res) {
      const { pipelines } = res.data;
      if (pipelines.length > 0) {
        // The pipeline entity always keeps the latest pipeline info on the `details.status`
        this.ciStatus = pipelines[0].details.status;
      }
      this.isLoading = false;
    },
    errorCallback() {
      this.ciStatus = {
        text: __('not found'),
        icon: 'status_notfound',
        group: 'notfound',
      };
      this.isLoading = false;
      createFlash({
        message: s__('Something went wrong on our end'),
      });
    },
    initPolling() {
      this.poll = new Poll({
        resource: this.service,
        method: 'fetchData',
        successCallback: (response) => this.successCallback(response),
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
      this.service.fetchData().then(this.successCallback).catch(this.errorCallback);
    },
  },
};
</script>
<template>
  <div class="ci-status-link">
    <gl-loading-icon v-if="isLoading" size="lg" label="Loading pipeline status" />
    <a v-else :href="ciStatus.details_path">
      <ci-icon
        v-gl-tooltip
        :title="statusTitle"
        :aria-label="statusTitle"
        :status="ciStatus"
        :size="24"
        data-container="body"
      />
    </a>
  </div>
</template>
