<script>
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

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
        historyPushState(setUrlParams(newQuery, window.location.href, true));
      },
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
