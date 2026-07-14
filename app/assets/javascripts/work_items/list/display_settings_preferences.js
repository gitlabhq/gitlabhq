import produce from 'immer';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import {
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED,
  METADATA_KEYS,
  VIEW_MODE_BOARD,
} from '~/work_items/constants';

// Shared helpers for persisting work item list display settings. These wrap the Apollo mutations
// and the getUserWorkItemsPreferences cache update so the drawer sub-components and planning_view
// don't each re-implement the same optimistic-response / cache.updateQuery plumbing.

export const alertPreferenceError = (error) =>
  createAlert({
    message: __('Something went wrong while saving the preference.'),
    captureError: true,
    error,
  });

export const applicableMetadataFields = ({ isGroup, isServiceDeskList, viewMode }) =>
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED.filter((item) => {
    // Some fields are tailored to the list view only, so they are not offered
    // as toggles while the board view is active.
    if (viewMode === VIEW_MODE_BOARD && !item.isAvailableInBoard) {
      return false;
    }
    return item.key === METADATA_KEYS.STATUS
      ? !isServiceDeskList
      : !isGroup || item.isPresentInGroup;
  });

const updateUserPreferencesCache = (
  cache,
  { namespace, workItemTypeId, userPreferencesOnly },
  mutate,
) =>
  cache.updateQuery(
    {
      query: getUserWorkItemsPreferences,
      variables: { namespace, workItemTypeId, userPreferencesOnly },
    },
    (existingData) => produce(existingData, (draftData) => mutate(draftData)),
  );

const buildListPreferenceOptimisticResponse = ({ displaySettings, sort }) => ({
  workItemUserPreferenceUpdate: {
    errors: [],
    userPreferences: {
      displaySettings,
      sort,
      __typename: 'WorkItemTypesUserPreference',
    },
    __typename: 'WorkItemUserPreferenceUpdatePayload',
  },
});

export const persistMetadataPreference = ({
  apolloClient,
  namespace,
  workItemTypeId,
  userPreferencesOnly,
  displaySettings,
  sort,
}) =>
  apolloClient.mutate({
    mutation: updateWorkItemListUserPreference,
    variables: { namespace, displaySettings },
    optimisticResponse: buildListPreferenceOptimisticResponse({ displaySettings, sort }),
    update: (
      cache,
      {
        data: {
          workItemUserPreferenceUpdate: { userPreferences },
        },
      },
    ) =>
      updateUserPreferencesCache(
        cache,
        { namespace, workItemTypeId, userPreferencesOnly },
        (draftData) => {
          if (draftData?.currentUser) {
            draftData.currentUser.workItemPreferences = {
              ...(draftData?.currentUser?.workItemPreferences ?? {}),
              displaySettings: userPreferences.displaySettings,
            };
          }
        },
      ),
  });

export const persistSortPreference = ({ apolloClient, namespace, workItemTypeId, sort }) =>
  apolloClient.mutate({
    mutation: updateWorkItemListUserPreference,
    variables: { namespace, workItemTypeId, sort },
    update: (
      cache,
      {
        data: {
          workItemUserPreferenceUpdate: { userPreferences },
        },
      },
    ) => {
      if (!userPreferences) {
        return;
      }

      cache.updateQuery(
        {
          query: getUserWorkItemsPreferences,
          variables: { namespace, workItemTypeId },
        },
        (existingData) =>
          produce(existingData, (draftData) => {
            draftData.currentUser.workItemPreferencesWithType.sort = userPreferences.sort;
          }),
      );
    },
  });

export const persistSidePanelPreference = ({
  apolloClient,
  namespace,
  workItemTypeId,
  userPreferencesOnly,
  shouldOpenItemsInSidePanel,
}) =>
  apolloClient.mutate({
    mutation: updateWorkItemsDisplaySettings,
    variables: { input: { workItemsDisplaySettings: { shouldOpenItemsInSidePanel } } },
    update: (
      cache,
      {
        data: {
          userPreferencesUpdate: { userPreferences },
        },
      },
    ) =>
      updateUserPreferencesCache(
        cache,
        { namespace, workItemTypeId, userPreferencesOnly },
        (draftData) => {
          if (draftData?.currentUser?.userPreferences) {
            draftData.currentUser.userPreferences.workItemsDisplaySettings =
              userPreferences.workItemsDisplaySettings;
          }
        },
      ),
  });
