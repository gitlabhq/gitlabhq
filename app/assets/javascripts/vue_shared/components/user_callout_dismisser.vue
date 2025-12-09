<script>
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import getUserCalloutsQuery from '~/graphql_shared/queries/get_user_callouts.query.graphql';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

/**
 * A renderless component for querying/dismissing UserCallouts via GraphQL.
 *
 * To use this component your Vue app must have an apollo client set up.
 * https://docs.gitlab.com/development/fe_guide/graphql/#usage-in-vue
 *
 * Simplest example usage:
 *
 *     <user-callout-dismisser feature-name="my_user_callout">
 *       <template #default="{ dismiss, shouldShowCallout }">
 *         <my-callout-component
 *           v-if="shouldShowCallout"
 *           @close="dismiss"
 *         />
 *       </template>
 *     </user-callout-dismisser>
 *
 * If you don't want the asynchronous query to run when the component is
 * created, and know by some other means whether the user callout has already
 * been dismissed, you can use the `skipQuery` prop, and a regular `v-if`
 * directive:
 *
 *     <user-callout-dismisser
 *       v-if="userCalloutIsNotDismissed"
 *       feature-name="my_user_callout"
 *       skip-query
 *     >
 *       <template #default="{ dismiss, shouldShowCallout }">
 *         <my-callout-component
 *           v-if="shouldShowCallout"
 *           @close="dismiss"
 *         />
 *       </template>
 *     </user-callout-dismisser>
 *
 *  The component exposes scoped slot props on the default slot:
 *
 *  - dismiss: Function
 *    - Triggers a mutation to dismiss the user callout.
 *  - shouldShowCallout: boolean
 *    - `true` if the query has loaded without error, the user is logged in,
 *      and the callout has not been dismissed yet; `false` otherwise.
 *
 * The component emits a `queryResult` event when the GraphQL query
 * completes. The payload is a combination of the ApolloQueryResult object and
 * this component's `slotProps` computed property. This is useful for things
 * like cleaning up/unmounting the component if the callout shouldn't be
 * displayed.
 */
export default normalizeRender({
  name: 'UserCalloutDismisser',
  props: {
    featureName: {
      type: String,
      required: true,
    },
    skipQuery: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      currentUser: null,
      isDismissedLocal: false,
      queryError: null,
    };
  },
  apollo: {
    currentUser: {
      query: getUserCalloutsQuery,
      update(data) {
        return data?.currentUser;
      },
      result(data) {
        this.$emit('queryResult', { ...data, ...this.slotProps });
      },
      error(err) {
        this.queryError = err;
      },
      skip() {
        return this.skipQuery;
      },
    },
  },
  computed: {
    featureNameEnumValue() {
      return this.featureName.toUpperCase();
    },
    isLoadingQuery() {
      return this.$apollo.queries.currentUser.loading;
    },
    isAnonUser() {
      return !(this.skipQuery || this.queryError || this.isLoadingQuery || this.currentUser);
    },
    isDismissedRemote() {
      const callouts = this.currentUser?.callouts?.nodes ?? [];

      return callouts.some(({ featureName }) => featureName === this.featureNameEnumValue);
    },
    isDismissed() {
      return this.isDismissedLocal || this.isDismissedRemote;
    },
    slotProps() {
      const { dismiss, shouldShowCallout } = this;

      return {
        dismiss,
        shouldShowCallout,
      };
    },
    shouldShowCallout() {
      return !(this.isLoadingQuery || this.isDismissed || this.queryError || this.isAnonUser);
    },
  },
  methods: {
    async dismiss() {
      this.isDismissedLocal = true;

      const mutationOptions = {
        mutation: dismissUserCalloutMutation,
        variables: {
          input: {
            featureName: this.featureName,
          },
        },
      };

      if (!this.skipQuery) {
        mutationOptions.refetchQueries = [{ query: getUserCalloutsQuery }];
      }

      await this.$apollo.mutate(mutationOptions);
    },
  },
  render() {
    return this.$scopedSlots.default(this.slotProps);
  },
});
</script>
