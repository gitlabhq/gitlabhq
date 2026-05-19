import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { findByTestId, findByGraphQLId, waitForElement, waitForAssertion } from '../test_helpers';
import {
  labelsResponse,
  autocompleteUsersResponse,
  milestonesResponse,
  baseUpdateResponse,
} from './handlers';

/**
 * Work item specific test helpers for MSW integration tests.
 * These helpers are specific to work item drawer/panel interactions.
 */

/**
 * Finds an element within the contextual panel portal by data-testid.
 * @param {string} testId - The data-testid value to search for
 * @returns {HTMLElement|null}
 */
export function findInDrawer(testId) {
  const portalEl = document.getElementById('contextual-panel-portal');
  if (!portalEl) return null;
  return findByTestId(testId, portalEl);
}

/**
 * Creates a portal element for testing drawer/modal interactions.
 * Should be called in beforeAll hook.
 * @param {string} [id='contextual-panel-portal'] - The ID for the portal element
 * @returns {HTMLElement}
 */
export function createPortalElement(id = 'contextual-panel-portal') {
  const existing = document.getElementById(id);
  if (existing) return existing;
  const portalEl = document.createElement('div');
  portalEl.id = id;
  document.body.appendChild(portalEl);
  return portalEl;
}

export const firstLabel = labelsResponse.data.namespace.labels.nodes[0];
export const firstUser = autocompleteUsersResponse.data.namespace.users[0];
export const firstMilestone = milestonesResponse.data.namespace.attributes.nodes[0];
export const workItemId = baseUpdateResponse.data.workItemUpdate.workItem.id;

function getListboxTestId(item) {
  return `listbox-item-${item.id}`;
}

export const findIssueToEdit = () => findByGraphQLId(workItemId, getIdFromGraphQLId);

export const findWorkItemDetail = () => findInDrawer('work-item-detail');
export const findEditFormButton = () => findInDrawer('work-item-edit-form-button');
export const findTitleInput = () => findInDrawer('work-item-title-input');
export const findWorkItemTitle = () => findInDrawer('work-item-title');
export const findDescriptionWrapper = () => findInDrawer('work-item-description-wrapper');
export const findAssigneesWidget = () => findInDrawer('work-item-assignees');
export const findLabelsWidget = () => findInDrawer('work-item-labels');
export const findActionsDropdown = () => findInDrawer('work-item-actions-dropdown');
export const findConfidentialityAction = () => findInDrawer('confidentiality-toggle-action');
export const findMilestoneWidget = () => findInDrawer('work-item-milestone');
export const findSubscribeButton = () => findInDrawer('subscribe-button');
export const findDatesWidget = () => findInDrawer('work-item-due-dates');
export const findConfirmButton = () => findInDrawer('confirm-button');
export const findApplyButton = () => findInDrawer('apply-button');
export const findStartDateValue = () => findInDrawer('start-date-value');
export const findDueDateValue = () => findInDrawer('due-date-value');
export const findUserListboxItem = () => findInDrawer(getListboxTestId(firstUser));
export const findLabelListboxItem = () => findInDrawer(getListboxTestId(firstLabel));
export const findMilestoneListboxItem = () => findInDrawer(getListboxTestId(firstMilestone));
export const findIssuableTitleLink = () => findByTestId('issuable-title-link', findIssueToEdit());
export const findAssigneeLink = () => findByTestId('assignee-link', findIssueToEdit());
export const findConfidentialIcon = () =>
  findByTestId('confidential-icon-container', findIssueToEdit());
export const findIssuableComments = () => findByTestId('issuable-comments', findIssueToEdit());
export const findIssuableDueDate = () => findByTestId('issuable-due-date', findIssueToEdit());

export const clickIssue = () => {
  findIssueToEdit().click();
};

export const selectIssue = async () => {
  clickIssue();
  await waitForElement(findWorkItemDetail);
};

export const startEditing = async (finder) => {
  const widget = await waitForElement(finder);
  findByTestId('edit-button', widget).click();
  await waitForAssertion(() => {
    expect(finder().querySelector('[role="listbox"]')).not.toBe(null);
  });
};

export const closeListbox = (finder) => {
  findByTestId('base-dropdown-toggle', finder()).click();
};
