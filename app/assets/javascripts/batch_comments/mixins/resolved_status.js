import { sprintf, __ } from '~/locale';

export default {
  computed: {
    resolveButtonTitle() {
      let title = __('Mark comment as resolved');

      if (this.resolvedBy) {
        title = sprintf(__('Resolved by %{name}'), { name: this.resolvedBy.name });
      }

      return title;
    },
  },
};
