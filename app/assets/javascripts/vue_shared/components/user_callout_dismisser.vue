<script>
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import getUserCalloutsQuery from '~/graphql_shared/queries/get_user_callouts.query.graphql';

/**
 * A renderless component for querying/dismissing UserCallouts via GraphQL.
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
 * The component exposes various scoped slot props on the default slot,
 * allowing for granular rendering behaviors based on the state of the initial
 * query and user-initiated mutation:
 *
 *  - dismiss: Function
 *    - Triggers mutation to dismiss the user callout.
 *  - isAnonUser: boolean
 *    - Whether the current user is anonymous or not (i.e., whether or not
 *      they're logged in).
 *  - isDismissed: boolean
 *    - Whether the given user callout has been dismissed or not.
 *  - isLoadingMutation: boolean
 *    - Whether the mutation is loading.
 *  - isLoadingQuery: boolean
 *    - Whether the initial query is loading.
 *  - mutationError: string[] | null
 *    - The mutation's errors, if any; otherwise `null`.
 *  - queryError: Error | null
 *    - The query's error, if any; otherwise `null`.
 *  - shouldShowCallout: boolean
 *    - A combination of the above which should cover 95% of use cases: `true`
 *      if the query has loaded without error, and the user is logged in, and
 *      the callout has not been dismissed yet; `false` otherwise.
 */
export default {
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
      isLoadingMutation: false,
      mutationError: null,
      queryError: null,
    };
  },
  apollo: {
    currentUser: {
      query: getUserCalloutsQuery,
      update(data) {
        return data?.currentUser;
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
      const {
        dismiss,
        isAnonUser,
        isDismissed,
        isLoadingMutation,
        isLoadingQuery,
        mutationError,
        queryError,
        shouldShowCallout,
      } = this;

      return {
        dismiss,
        isAnonUser,
        isDismissed,
        isLoadingMutation,
        isLoadingQuery,
        mutationError,
        queryError,
        shouldShowCallout,
      };
    },
    shouldShowCallout() {
      return !(this.isLoadingQuery || this.isDismissed || this.queryError || this.isAnonUser);
    },
  },
  methods: {
    async dismiss() {
      this.isLoadingMutation = true;
      this.isDismissedLocal = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: dismissUserCalloutMutation,
          variables: {
            input: {
              featureName: this.featureName,
            },
          },
        });

        const errors = data?.userCalloutCreate?.errors ?? [];
        if (errors.length > 0) {
          this.onDismissalError(errors);
        }
      } catch (err) {
        this.onDismissalError([err.message]);
      } finally {
        this.isLoadingMutation = false;
      }
    },
    onDismissalError(errors) {
      this.mutationError = errors;
    },
  },
  render() {
    return this.$scopedSlots.default(this.slotProps);
  },
};
</script>
