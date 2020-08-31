import { __, sprintf } from '~/locale';

export const issuableTypesMap = {
  ISSUE: 'issue',
  EPIC: 'epic',
  MERGE_REQUEST: 'merge_request',
};

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
    [issuableTypesMap.ISSUE]: sprintf(
      __(' or %{emphasisStart}#issue id%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
    [issuableTypesMap.EPIC]: sprintf(
      __(' or %{emphasisStart}&epic id%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
    [issuableTypesMap.MERGE_REQUEST]: sprintf(
      __(' or %{emphasisStart}!merge request id%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
  },
  false: {
    [issuableTypesMap.ISSUE]: '',
    [issuableTypesMap.EPIC]: '',
    [issuableTypesMap.MERGE_REQUEST]: __(' or references (e.g. path/to/project!merge_request_id)'),
  },
};

export const inputPlaceholderTextMap = {
  [issuableTypesMap.ISSUE]: __('Paste issue link'),
  [issuableTypesMap.EPIC]: __('Paste epic link'),
  [issuableTypesMap.MERGE_REQUEST]: __('Enter merge request URLs'),
};

export const inputPlaceholderConfidentialTextMap = {
  [issuableTypesMap.ISSUE]: __('Paste confidential issue link'),
  [issuableTypesMap.EPIC]: __('Paste confidential epic link'),
  [issuableTypesMap.MERGE_REQUEST]: __('Enter merge request URLs'),
};

export const relatedIssuesRemoveErrorMap = {
  [issuableTypesMap.ISSUE]: __('An error occurred while removing issues.'),
  [issuableTypesMap.EPIC]: __('An error occurred while removing epics.'),
};

export const pathIndeterminateErrorMap = {
  [issuableTypesMap.ISSUE]: __('We could not determine the path to remove the issue'),
  [issuableTypesMap.EPIC]: __('We could not determine the path to remove the epic'),
};

export const itemAddFailureTypesMap = {
  NOT_FOUND: 'not_found',
  MAX_NUMBER_OF_CHILD_EPICS: 'conflict',
};

export const addRelatedIssueErrorMap = {
  [issuableTypesMap.ISSUE]: __('Issue cannot be found.'),
  [issuableTypesMap.EPIC]: __('Epic cannot be found.'),
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
  [issuableTypesMap.ISSUE]: 'issues',
  [issuableTypesMap.EPIC]: 'epic',
};

/**
 * These are used to map issuableType to the correct QA class.
 * Since these are never used for any display purposes, don't wrap
 * them inside i18n functions.
 */
export const issuableQaClassMap = {
  [issuableTypesMap.EPIC]: 'qa-add-epics-button',
};

export const PathIdSeparator = {
  Epic: '&',
  Issue: '#',
};
