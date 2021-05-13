import { s__ } from '~/locale';

export default {
  computed: {
    statusTextBeforeAuthor() {
      return s__('mrWidget|Set by');
    },
    statusTextAfterAuthor() {
      return s__('mrWidget|to be merged automatically when the pipeline succeeds');
    },
    cancelButtonText() {
      return s__('mrWidget|Cancel');
    },
  },
};
