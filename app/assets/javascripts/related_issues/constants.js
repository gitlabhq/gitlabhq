import { __, sprintf } from '~/locale';
import { TYPE_EPIC, TYPE_INCIDENT, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';

export const linkedIssueTypesMap = {
  BLOCKS: 'blocks',
  IS_BLOCKED_BY: 'is_blocked_by',
  RELATES_TO: 'relates_to',
};

export const linkedIssueTypesTextMap = {
  [linkedIssueTypesMap.RELATES_TO]: __('Relates to'),
  [linkedIssueTypesMap.BLOCKS]: __('Blocks'),
  [linkedIssueTypesMap.IS_BLOCKED_BY]: __('Is blocked by'),
};

export const autoCompleteTextMap = {
  true: {
    [TYPE_ISSUE]: sprintf(
      __(' or %{emphasisStart}#issue ID%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
    [TYPE_INCIDENT]: sprintf(
      __(' or %{emphasisStart}#ID%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
    [TYPE_EPIC]: sprintf(
      __(' or %{emphasisStart}&epic ID%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
    [TYPE_MERGE_REQUEST]: sprintf(
      __(' or %{emphasisStart}!merge request ID%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
  },
  false: {
    [TYPE_ISSUE]: '',
    [TYPE_EPIC]: '',
    [TYPE_MERGE_REQUEST]: __(' or references'),
  },
};

export const inputPlaceholderTextMap = {
  [TYPE_ISSUE]: __('Enter issue URL'),
  [TYPE_INCIDENT]: __('Enter URL'),
  [TYPE_EPIC]: __('Enter epic URL'),
  [TYPE_MERGE_REQUEST]: __('Enter merge request URLs'),
};

export const inputPlaceholderConfidentialTextMap = {
  [TYPE_ISSUE]: __('Enter confidential issue URL'),
  [TYPE_EPIC]: __('Enter confidential epic URL'),
  [TYPE_MERGE_REQUEST]: __('Enter merge request URLs'),
};

export const relatedIssuesRemoveErrorMap = {
  [TYPE_ISSUE]: __('An error occurred while removing issues.'),
  [TYPE_EPIC]: __('An error occurred while removing epics.'),
};

export const pathIndeterminateErrorMap = {
  [TYPE_ISSUE]: __('We could not determine the path to remove the issue'),
  [TYPE_EPIC]: __('We could not determine the path to remove the epic'),
};

export const itemAddFailureTypesMap = {
  NOT_FOUND: 'not_found',
  MAX_NUMBER_OF_CHILD_EPICS: 'conflict',
};

export const addRelatedIssueErrorMap = {
  [TYPE_ISSUE]: __('Issue cannot be found.'),
  [TYPE_EPIC]: __('Epic cannot be found.'),
};

export const addRelatedItemErrorMap = {
  [itemAddFailureTypesMap.MAX_NUMBER_OF_CHILD_EPICS]: __(
    'This epic already has the maximum number of child epics.',
  ),
};

/**
 * These are used to map issuableType to the correct icon.
 * Since these are never used for any display purposes, don't wrap
 * them inside i18n functions.
 */
export const issuableIconMap = {
  [TYPE_ISSUE]: 'issues',
  [TYPE_INCIDENT]: 'issues',
  [TYPE_EPIC]: 'epic',
};

export const PathIdSeparator = {
  Epic: '&',
  Issue: '#',
};

export const issuablesBlockHeaderTextMap = {
  [TYPE_ISSUE]: __('Linked items'),
  [TYPE_INCIDENT]: __('Linked incidents or issues'),
  [TYPE_EPIC]: __('Linked epics'),
};

export const issuablesBlockHelpTextMap = {
  [TYPE_ISSUE]: __('Learn more about linking issues'),
  [TYPE_INCIDENT]: __('Learn more about linking issues and incidents'),
  [TYPE_EPIC]: __('Learn more about linking epics'),
};

export const issuablesBlockAddButtonTextMap = {
  [TYPE_ISSUE]: __('Add a related issue'),
  [TYPE_EPIC]: __('Add a related epic'),
};

export const issuablesFormCategoryHeaderTextMap = {
  [TYPE_ISSUE]: __('The current issue'),
  [TYPE_INCIDENT]: __('The current incident'),
  [TYPE_EPIC]: __('The current epic'),
};

export const issuablesFormInputTextMap = {
  [TYPE_ISSUE]: __('the following issues'),
  [TYPE_INCIDENT]: __('the following incidents or issues'),
  [TYPE_EPIC]: __('the following epics'),
};
