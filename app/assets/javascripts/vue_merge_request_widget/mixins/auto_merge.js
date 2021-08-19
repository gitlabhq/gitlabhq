import { s__ } from '~/locale';

export default {
  computed: {
    statusText() {
      return s__(
        'mrWidget|Set by %{merge_author} to be merged automatically when the pipeline succeeds',
      );
    },
    cancelButtonText() {
      return s__('mrWidget|Cancel auto-merge');
    },
  },
};
