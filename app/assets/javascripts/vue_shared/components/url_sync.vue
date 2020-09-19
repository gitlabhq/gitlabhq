<script>
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';

export default {
  props: {
    query: {
      type: Object,
      required: true,
    },
  },
  watch: {
    query: {
      immediate: true,
      deep: true,
      handler(newQuery) {
        historyPushState(mergeUrlParams(newQuery, window.location.href, { spreadArrays: true }));
      },
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
