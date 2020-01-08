import Visibility from 'visibilityjs';
import PipelineStore from './stores/pipeline_store';
import Flash from '../flash';
import Poll from '../lib/utils/poll';
import { __ } from '../locale';
import PipelineService from './services/pipeline_service';

export default class pipelinesMediator {
  constructor(options = {}) {
    this.options = options;
    this.store = new PipelineStore();
    this.service = new PipelineService(options.endpoint);

    this.state = {};
    this.state.isLoading = false;
  }

  fetchPipeline() {
    this.poll = new Poll({
      resource: this.service,
      method: 'getPipeline',
      data: this.store.state.expandedPipelines ? this.getExpandedParameters() : undefined,
      successCallback: this.successCallback.bind(this),
      errorCallback: this.errorCallback.bind(this),
    });

    if (!Visibility.hidden()) {
      this.state.isLoading = true;
      this.poll.makeRequest();
    } else {
      this.refreshPipeline();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.stopPipelinePoll();
      }
    });
  }

  successCallback(response) {
    this.state.isLoading = false;
    this.store.storePipeline(response.data);
  }

  errorCallback() {
    this.state.isLoading = false;
    Flash(__('An error occurred while fetching the pipeline.'));
  }

  refreshPipeline() {
    this.stopPipelinePoll();

    return this.service
      .getPipeline()
      .then(response => this.successCallback(response))
      .catch(() => this.errorCallback())
      .finally(() =>
        this.poll.restart(
          this.store.state.expandedPipelines ? this.getExpandedParameters() : undefined,
        ),
      );
  }

  stopPipelinePoll() {
    this.poll.stop();
  }

  /**
   * Backend expects paramets in the following format: `expanded[]=id&expanded[]=id`
   */
  getExpandedParameters() {
    return {
      expanded: this.store.state.expandedPipelines,
    };
  }
}
