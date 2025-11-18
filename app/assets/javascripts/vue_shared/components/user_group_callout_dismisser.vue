<script>
import dismissUserGroupCalloutMutation from '~/graphql_shared/mutations/dismiss_user_group_callout.mutation.graphql';
import getUserGroupCalloutsQuery from '~/graphql_shared/queries/get_user_group_callouts.query.graphql';
import { isGid, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { logError } from '~/lib/logger';

/**
 * A renderless component for querying/dismissing Users::GroupCallouts via GraphQL.
 *
 * Simplest example usage:
 *
 *   <user-group-callout-dismisser
 *     feature-name="my_user_callout"
 *    :group-id="groupId"
 *   >
 *     <template #default="{ dismiss, shouldShowCallout }">
 *       <my-callout-component v-if="shouldShowCallout" @close="dismiss" />
 *     </template>
 *   </user-group-callout-dismisser>
 *
 * The groupId prop accepts both numeric IDs (e.g., 123) and GraphQL IDs
 * (e.g., 'gid://gitlab/Group/123'). The component handles the conversion
 * to GraphQL format internally.
 *
 * If you don't want the asynchronous query to run when the component is
 * created, and know by some other means whether the user callout has already
 * been dismissed, you can use the `skipQuery` prop, and a regular `v-if`
 * directive:
 *
 *     <user-group-callout-dismisser
 *       v-if="userCalloutIsNotDismissed"
 *       feature-name="my_user_callout"
 *       :group-id="groupId"
 *       skip-query
 *     >
 *       <template #default="{ dismiss, shouldShowCallout }">
 *         <my-callout-component
 *           v-if="shouldShowCallout"
 *           @close="dismiss"
 *         />
 *       </template>
 *     </user-group-callout-dismisser>
 *
 * The component exposes various scoped slot props on the default slot,
 * allowing for granular rendering behaviors based on the state of the initial
 * query and user-initiated mutation:
 *
 *  - dismiss: Function
 *    - Triggers mutation to dismiss the user callout.
 *  - shouldShowCallout: boolean
 *    - `true` if the query has loaded without error, and the user is logged in, and
 *      the callout has not been dismissed yet; `false` otherwise
 */
export default {
  name: 'UserGroupCalloutDismisser',
  props: {
    groupId: {
      type: [String, Number],
      required: true,
    },
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
      query: getUserGroupCalloutsQuery,
      update(data) {
        return data?.currentUser;
      },
      error(err) {
        logError(err);
        Sentry.captureException(err);
        this.queryError = err;
      },
      skip() {
        return this.skipQuery;
      },
    },
  },
  computed: {
    groupGraphQLId() {
      return typeof this.groupId === 'string' && isGid(this.groupId)
        ? this.groupId
        : convertToGraphQLId(TYPENAME_GROUP, this.groupId);
    },
    featureNameEnumValue() {
      return this.featureName.toUpperCase();
    },
    isLoadingQuery() {
      return this.$apollo.queries.currentUser.loading;
    },
    isAnonUser() {
      return !this.skipQuery && !this.queryError && !this.isLoadingQuery && !this.currentUser;
    },
    isDismissedRemote() {
      const callouts = this.currentUser?.groupCallouts?.nodes ?? [];

      return callouts.some(
        ({ featureName, groupId }) =>
          featureName === this.featureNameEnumValue && groupId === this.groupGraphQLId,
      );
    },
    isDismissed() {
      return this.isDismissedLocal || this.isDismissedRemote;
    },
    slotProps() {
      const { dismiss, shouldShowCallout } = this;

      return { dismiss, shouldShowCallout };
    },
    shouldShowCallout() {
      return !this.isLoadingQuery && !this.isDismissed && !this.queryError && !this.isAnonUser;
    },
  },
  methods: {
    async dismiss() {
      this.isLoadingMutation = true;
      this.isDismissedLocal = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: dismissUserGroupCalloutMutation,
          variables: {
            input: {
              featureName: this.featureName,
              groupId: this.groupGraphQLId,
            },
          },
        });

        const errors = data?.userGroupCalloutCreate?.errors;
        if (errors?.length > 0) {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          const errorMessage = `User group callout dismissal failed: ${errors.join(', ')}`;
          Sentry.captureException(new Error(errorMessage));
          this.onDismissalError(errors);
        }
      } catch (err) {
        logError(err);
        Sentry.captureException(err);
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
