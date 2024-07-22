<script>
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

export default {
  name: 'WorkItemPrefetch',
  inject: {
    fullPath: {
      default: '',
    },
  },
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      skipQuery: true,
    };
  },
  apollo: {
    workItem: {
      query() {
        return workItemByIidQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.fullPath || this.skipQuery;
      },
      update(data) {
        return data.workspace.workItem ?? {};
      },
    },
  },
  methods: {
    prefetchWorkItem() {
      this.prefetch = setTimeout(() => {
        this.skipQuery = false;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    clearPrefetching() {
      if (this.prefetch) {
        clearTimeout(this.prefetch);
        this.prefetch = null;
      }
    },
  },
  render() {
    return this.$scopedSlots.default({
      prefetchWorkItem: this.prefetchWorkItem,
      clearPrefetching: this.clearPrefetching,
    });
  },
};
</script>
