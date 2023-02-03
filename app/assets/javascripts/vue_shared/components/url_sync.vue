<script>
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams, setUrlParams } from '~/lib/utils/url_utility';

export const URL_SET_PARAMS_STRATEGY = 'set';
export const URL_MERGE_PARAMS_STRATEGY = 'merge';

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
    urlParamsUpdateStrategy: {
      type: String,
      required: false,
      default: URL_MERGE_PARAMS_STRATEGY,
      validator: (value) => [URL_MERGE_PARAMS_STRATEGY, URL_SET_PARAMS_STRATEGY].includes(value),
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
      const url =
        this.urlParamsUpdateStrategy === URL_SET_PARAMS_STRATEGY
          ? setUrlParams(this.query, window.location.href, true, true, true)
          : mergeUrlParams(newQuery, window.location.href, { spreadArrays: true });
      historyPushState(url);
    },
  },
  render() {
    return this.$scopedSlots.default?.({ updateQuery: this.updateQuery });
  },
};
</script>
