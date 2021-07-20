import createFlash from '~/flash';
import { __ } from '~/locale';

export default {
  methods: {
    getExpandedPipelines(pipeline) {
      this.mediator.service
        .getPipeline(this.mediator.getExpandedParameters())
        .then((response) => {
          this.mediator.store.toggleLoading(pipeline);
          this.mediator.store.storePipeline(response.data);
          this.mediator.poll.enable({ data: this.mediator.getExpandedParameters() });
        })
        .catch(() => {
          this.mediator.store.toggleLoading(pipeline);
          createFlash({
            message: __('An error occurred while fetching the pipeline.'),
          });
        });
    },
    /**
     * Called when a linked pipeline is clicked.
     *
     * If the pipeline is collapsed we will start polling it & we will reset the other pipelines.
     * If the pipeline is expanded we will close it.
     *
     * @param {String} method Method to fetch the pipeline
     * @param {String} storeKey Store property that will be updates
     * @param {String} resetStoreKey Store key for the visible pipeline that will need to be reset
     * @param {Object} pipeline The clicked pipeline
     */
    clickPipeline(pipeline, openMethod, closeMethod) {
      if (!pipeline.isExpanded) {
        this.mediator.store[openMethod](pipeline);
        this.mediator.store.toggleLoading(pipeline);
        this.mediator.poll.stop();

        this.getExpandedPipelines(pipeline);
      } else {
        this.mediator.store[closeMethod](pipeline);
        this.mediator.poll.stop();

        this.mediator.poll.enable({ data: this.mediator.getExpandedParameters() });
      }
    },
    resetDownstreamPipelines(parentPipeline, pipeline) {
      this.mediator.store.resetTriggeredPipelines(parentPipeline, pipeline);
    },
    clickUpstreamPipeline(pipeline) {
      this.clickPipeline(pipeline, 'openPipeline', 'closePipeline');
    },
    clickDownstreamPipeline(pipeline) {
      this.clickPipeline(pipeline, 'openPipeline', 'closePipeline');
    },
    requestRefreshPipelineGraph() {
      // When an action is clicked
      // (whether in the dropdown or in the main nodes, we refresh the big graph)
      this.mediator.refreshPipeline().catch(() =>
        createFlash({
          message: __('An error occurred while making the request.'),
        }),
      );
    },
  },
};
