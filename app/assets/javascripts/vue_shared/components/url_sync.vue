<script>
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';

/**
 * Renderless component to update the query string,
 * the update is done by updating the query property or
 * by using updateQuery method in the scoped slot.
 * note: do not use both prop and updateQuery method.
 */
export default {
  props: {
    query: {
      type: Object,
      required: false,
      default: null,
    },
  },
  watch: {
    query: {
      immediate: true,
      deep: true,
      handler(newQuery) {
        if (newQuery) {
          this.updateQuery(newQuery);
        }
      },
    },
  },
  methods: {
    updateQuery(newQuery) {
      historyPushState(mergeUrlParams(newQuery, window.location.href, { spreadArrays: true }));
    },
  },
  render() {
    return this.$scopedSlots.default?.({ updateQuery: this.updateQuery });
  },
};
</script>
