<script>
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

export default normalizeRender({
  name: 'WorkItemPrefetch',
  inject: {
    fullPath: {
      default: '',
    },
  },
  inheritAttrs: false,
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  mixins: [glFeatureFlagsMixin()],
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
          fullPath: this.workItemFullPath || this.fullPath,
          iid: this.workItemIid,
          useWorkItemFeatures: Boolean(this.glFeatures.workItemFeaturesField),
        };
      },
      skip() {
        return !this.fullPath || this.skipQuery;
      },
      update(data) {
        return data.namespace?.workItem ?? {};
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
});
</script>
