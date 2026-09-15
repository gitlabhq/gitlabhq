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

// Helpers for saving work item list display settings. Saving a setting always means running
// the same Apollo mutation and updating the cache the same way, so this module does that once
// instead of the drawer sub-components and planning_view each writing their own copy.

export const alertPreferenceError = (error) =>
  createAlert({
    message: __('Something went wrong while saving the preference.'),
    captureError: true,
    error,
  });

export const applicableMetadataFields = ({ isServiceDeskList, viewMode }) =>
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED.filter((item) => {
    // The board card has no markup for some fields, so they get no toggle there.
    if (viewMode === VIEW_MODE_BOARD && !item.isAvailableInBoard) {
      return false;
    }
    if (item.key === METADATA_KEYS.STATUS) {
      return !isServiceDeskList;
    }
    return true;
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
