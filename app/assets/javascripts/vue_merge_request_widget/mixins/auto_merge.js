import { s__ } from '~/locale';
import { MWCP_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';

export default {
  computed: {
    statusText() {
      const { autoMergeStrategy } = this.state.mergeRequest;

      if (autoMergeStrategy === MWCP_MERGE_STRATEGY) {
        return s__(
          'mrWidget|Set by %{merge_author} to be merged automatically when all merge checks pass',
        );
      }

      return s__(
        'mrWidget|Set by %{merge_author} to be merged automatically when the pipeline succeeds',
      );
    },
    cancelButtonText() {
      return s__('mrWidget|Cancel auto-merge');
    },
  },
};
