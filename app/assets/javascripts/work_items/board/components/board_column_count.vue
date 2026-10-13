<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import { boardColumnCountVariables } from '../utils';

// Renders nothing. Runs one group's count query and reports the result
// upward, so board_view can tell which groups are empty.
export default normalizeRender({
  name: 'BoardColumnCount',
  props: {
    value: {
      type: Object,
      required: true,
    },
    strategy: {
      type: Object,
      required: true,
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
    baseQueryVariables: {
      type: Object,
      required: true,
    },
  },
  emits: ['change'],
  data() {
    return {
      totalCount: 0,
    };
  },
  computed: {
    countQueryVariables() {
      return boardColumnCountVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.baseQueryVariables,
        groupFilter: this.strategy.groupFilter(this.value),
      });
    },
  },
  apollo: {
    totalCount() {
      return {
        query: getWorkItemsCountOnlyQuery,
        variables() {
          return this.countQueryVariables;
        },
        update(data) {
          return data?.namespace?.workItems?.count ?? 0;
        },
        result({ data, error }) {
          if (error) {
            return;
          }
          this.$emit('change', {
            valueId: this.value.id,
            count: data?.namespace?.workItems?.count ?? 0,
          });
        },
        error(error) {
          Sentry.captureException(error);
          // An unknown count must not hide a group that might not be empty.
          this.$emit('change', { valueId: this.value.id, count: null });
        },
      };
    },
  },
  render() {
    return null;
  },
});
</script>
