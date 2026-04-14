import canCreateBranchResponse from 'test_fixtures/graphql/work_items/integration/can_create_branch.json';
import workItemMetadataResponse from 'test_fixtures/graphql/work_items/integration/work_item_metadata.query.graphql.json';
import stateCountsResponse from 'test_fixtures/graphql/work_items/integration/get_work_item_state_counts.query.graphql.json';
import workItemsFullResponse from 'test_fixtures/graphql/work_items/integration/get_work_items_full.query.graphql.json';
import workItemsSlimResponse from 'test_fixtures/graphql/work_items/integration/get_work_items_slim.query.graphql.json';
import namespaceWorkItemResponse from 'test_fixtures/graphql/work_items/integration/namespace_work_item.query.graphql.json';
import currentUserResponse from 'test_fixtures/graphql/work_items/integration/current_user.query.graphql.json';
import workspacePermissionsResponse from 'test_fixtures/graphql/work_items/integration/workspace_permissions.query.graphql.json';
import workItemTypesResponse from 'test_fixtures/graphql/work_items/integration/namespace_work_item_types.query.graphql.json';
import ancestorsResponse from 'test_fixtures/graphql/work_items/integration/work_item_ancestors.query.graphql.json';
import notesByIidResponse from 'test_fixtures/graphql/work_items/integration/work_item_notes_by_iid.query.graphql.json';
import linkedItemsResponse from 'test_fixtures/graphql/work_items/integration/work_item_linked_items.query.graphql.json';
import allowedChildTypesResponse from 'test_fixtures/graphql/work_items/integration/work_item_allowed_children.query.graphql.json';
import allowedParentTypesResponse from 'test_fixtures/graphql/work_items/integration/work_item_allowed_parent_types.query.graphql.json';
import notificationsResponse from 'test_fixtures/graphql/work_items/integration/get_work_item_notifications_by_id.query.graphql.json';
import treeResponse from 'test_fixtures/graphql/work_items/integration/work_item_tree.query.graphql.json';
import aiPermissionsResponse from 'test_fixtures/graphql/work_items/integration/ai_permissions_for_project.query.graphql.json';
import awardEmojisResponse from 'test_fixtures/graphql/work_items/integration/award_emoji.query.graphql.json';
import participantsResponse from 'test_fixtures/graphql/work_items/integration/work_item_participants.query.graphql.json';
import designListResponse from 'test_fixtures/graphql/work_items/integration/design_collection.query.graphql.json';
import namespacePathsResponse from 'test_fixtures/graphql/work_items/integration/namespace_paths.query.graphql.json';
import vulnerabilitiesResponse from 'test_fixtures/graphql/work_items/integration/work_item_vulnerabilities.query.graphql.json';
import labelsResponse from 'test_fixtures/graphql/work_items/integration/project_labels.query.graphql.json';
import mergeRequestsEnabledResponse from 'test_fixtures/graphql/work_items/integration/namespace_merge_requests_enabled.query.graphql.json';
import projectRootRefResponse from 'test_fixtures/graphql/work_items/integration/get_project_root_ref.query.graphql.json';
import developmentResponse from 'test_fixtures/graphql/work_items/integration/work_item_development.query.graphql.json';
import groupPermissionsResponse from 'test_fixtures/graphql/work_items/integration/group_workspace_permissions.query.graphql.json';
import hasWorkItemsResponse from 'test_fixtures/graphql/work_items/integration/has_work_items.query.graphql.json';
import descriptionTemplatesResponse from 'test_fixtures/graphql/work_items/integration/work_item_description_templates_list.query.graphql.json';
import autocompleteUsersResponse from 'test_fixtures/graphql/work_items/integration/workspace_autocomplete_users.query.graphql.json';
import userPreferencesResponse from 'test_fixtures/graphql/work_items/integration/get_user_preferences.query.graphql.json';
import customFieldNamesResponse from 'test_fixtures/graphql/work_items/integration/custom_field_names.query.graphql.json';
import workItemTypesConfigResponse from 'test_fixtures/graphql/work_items/integration/work_item_types_configuration.query.graphql.json';
import duoWorkflowStatusResponse from 'test_fixtures/graphql/work_items/integration/get_duo_workflow_status_check.query.graphql.json';
import emailParticipantsResponse from 'test_fixtures/graphql/work_items/integration/work_item_email_participants_by_iid.query.graphql.json';
import configuredFlowsResponse from 'test_fixtures/graphql/work_items/integration/get_configured_flows.query.graphql.json';
import milestonesResponse from 'test_fixtures/graphql/work_items/integration/project_milestones.query.graphql.json';
import baseUpdateResponse from 'test_fixtures/graphql/work_items/integration/update_work_item.mutation.graphql.json';
import updateLabelsResponse from 'test_fixtures/graphql/work_items/integration/update_work_item_labels.mutation.graphql.json';
import updateAssigneesResponse from 'test_fixtures/graphql/work_items/integration/update_work_item_assignees.mutation.graphql.json';
import updateMilestoneResponse from 'test_fixtures/graphql/work_items/integration/update_work_item_milestone.mutation.graphql.json';
import createNoteResponse from 'test_fixtures/graphql/work_items/integration/create_work_item_note.mutation.graphql.json';
import { buildUpdateResponse } from '../fixture_utils';

export {
  labelsResponse,
  autocompleteUsersResponse,
  milestonesResponse,
  baseUpdateResponse,
  canCreateBranchResponse,
};

const FIXTURE_RESPONSES = {
  workItemMetadataEE: workItemMetadataResponse,
  EEgetWorkItemStateCounts: stateCountsResponse,
  getWorkItemsFullEE: workItemsFullResponse,
  getWorkItemsSlimEE: workItemsSlimResponse,
  namespaceCustomFieldNames: customFieldNamesResponse,
  getUserWorkItemsPreferences: userPreferencesResponse,
  workspacePermissions: workspacePermissionsResponse,
  namespaceWorkItem: namespaceWorkItemResponse,
  getAllowedWorkItemChildTypes: allowedChildTypesResponse,
  getAllowedWorkItemParentTypes: allowedParentTypesResponse,
  workItemAncestorsQuery: ancestorsResponse,
  getWorkItemNotificationsById: notificationsResponse,
  workItemTreeQuery: treeResponse,
  projectGenerateDescriptionPermissions: aiPermissionsResponse,
  projectWorkItemAwardEmojis: awardEmojisResponse,
  workItemParticipants: participantsResponse,
  currentUser: currentUserResponse,
  getWorkItemDesignList: designListResponse,
  workItemLinkedItems: linkedItemsResponse,
  workItemNotesByIid: notesByIidResponse,
  namespacePaths: namespacePathsResponse,
  workItemVulnerabilities: vulnerabilitiesResponse,
  namespaceWorkItemTypes: workItemTypesResponse,
  projectLabels: labelsResponse,
  namespaceMergeRequestsEnabled: mergeRequestsEnabledResponse,
  getProjectRootRef: projectRootRefResponse,
  workItemDevelopment: developmentResponse,
  groupWorkspacePermissions: groupPermissionsResponse,
  hasWorkItems: hasWorkItemsResponse,
  workItemDescriptionTemplatesList: descriptionTemplatesResponse,
  workspaceAutocompleteUsersSearch: autocompleteUsersResponse,
  workItemTypesConfiguration: workItemTypesConfigResponse,
  getDuoWorkflowStatusCheck: duoWorkflowStatusResponse,
  workItemEmailParticipantsByIid: emailParticipantsResponse,
  getConfiguredFlows: configuredFlowsResponse,
  projectMilestones: milestonesResponse,
};

export function handleWorkItemOperation({ operationName, variables, res, ctx }) {
  if (operationName === 'createWorkItemNote') {
    return res(ctx.json(createNoteResponse));
  }

  if (operationName === 'workItemSubscribe') {
    return res(
      ctx.json({
        data: {
          workItemSubscribe: {
            errors: [],
            workItem: {
              __typename: 'WorkItem',
              id: variables.input.id,
              widgets: [
                {
                  type: 'NOTIFICATIONS',
                  subscribed: variables.input.subscribed,
                  __typename: 'WorkItemWidgetNotifications',
                },
              ],
            },
          },
        },
      }),
    );
  }

  if (operationName === 'workItemUpdate') {
    const updateResult = buildUpdateResponse({
      baseResponse: baseUpdateResponse,
      labelsFixture: updateLabelsResponse,
      assigneesFixture: updateAssigneesResponse,
      milestoneFixture: updateMilestoneResponse,
      input: variables.input,
    });
    return res(ctx.json(updateResult));
  }

  const fixture = FIXTURE_RESPONSES[operationName];

  if (fixture) {
    return res(ctx.json({ data: fixture.data }));
  }

  return null;
}

export const workItemRestEndpoints = [
  { method: 'get', path: /issues\/\d+\/can_create_branch/, response: canCreateBranchResponse },
];
