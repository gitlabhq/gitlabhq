<script>
import { fetchPolicies } from '~/lib/graphql';
import allRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners_count.query.graphql';
import groupRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners_count.query.graphql';

import { captureException } from '../../sentry_utils';
import { INSTANCE_TYPE, GROUP_TYPE } from '../../constants';

/**
 * Renderless component that wraps a "count" query for the
 * number of runners that follow a filter criteria.
 *
 * Example usage:
 *
 * Render the count of "online" runners in the instance in a
 * <strong/> tag.
 *
 * ```vue
 * <runner-count
 *   #default="{ count }"
 *   :scope="INSTANCE_TYPE"
 *   :variables="{ status: 'ONLINE' }"
 * >
 *   <strong>{{ count }}</strong>
 * </runner-count>
 * ```
 *
 * Use `:skip="true"` to prevent data from being fetched and
 * even rendered.
 */
export default {
  name: 'RunnerCount',
  props: {
    scope: {
      type: String,
      required: true,
      validator: (val) => [INSTANCE_TYPE, GROUP_TYPE].includes(val),
    },
    variables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    skip: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return { count: null };
  },
  apollo: {
    count: {
      query() {
        if (this.scope === INSTANCE_TYPE) {
          return allRunnersCountQuery;
        }
        if (this.scope === GROUP_TYPE) {
          return groupRunnersCountQuery;
        }
        return null;
      },
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return this.variables;
      },
      skip() {
        if (this.skip) {
          // Don't show data for skipped stats
          this.count = null;
        }
        return this.skip;
      },
      update(data) {
        if (this.scope === INSTANCE_TYPE) {
          return data?.runners?.count;
        }
        if (this.scope === GROUP_TYPE) {
          return data?.group?.runners?.count;
        }
        return null;
      },
      error(error) {
        this.reportToSentry(error);
      },
    },
  },
  methods: {
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },

    // Component API
    refetch() {
      // Parent components can use this method to refresh the count
      this.$apollo.queries.count.refetch();
    },
  },
  render() {
    return this.$scopedSlots.default({
      count: this.count,
    });
  },
};
</script>
