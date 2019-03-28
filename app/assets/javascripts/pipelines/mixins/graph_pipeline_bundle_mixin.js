import Flash from '~/flash';
import { __ } from '~/locale';

export default {
  methods: {
    clickTriggeredByPipeline() {},
    clickTriggeredPipeline() {},
    requestRefreshPipelineGraph() {
      // When an action is clicked
      // (wether in the dropdown or in the main nodes, we refresh the big graph)
      this.mediator
        .refreshPipeline()
        .catch(() => Flash(__('An error occurred while making the request.')));
    },
  },
};
