import { __, sprintf } from '~/locale';
import { TYPE_ISSUE } from '~/issues/constants';

export const issuableTypesMap = {
  ISSUE: 'issue',
  INCIDENT: 'incident',
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
    [TYPE_ISSUE]: sprintf(
      __(' or %{emphasisStart}#issue id%{emphasisEnd}'),
      { emphasisStart: '<', emphasisEnd: '>' },
      false,
    ),
    [issuableTypesMap.INCIDENT]: sprintf(
      __(' or %{emphasisStart}#id%{emphasisEnd}'),
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
    [TYPE_ISSUE]: '',
    [issuableTypesMap.EPIC]: '',
    [issuableTypesMap.MERGE_REQUEST]: __(' or references'),
  },
};

export const inputPlaceholderTextMap = {
  [TYPE_ISSUE]: __('Paste issue link'),
  [issuableTypesMap.INCIDENT]: __('Paste link'),
  [issuableTypesMap.EPIC]: __('Paste epic link'),
  [issuableTypesMap.MERGE_REQUEST]: __('Enter merge request URLs'),
};

export const inputPlaceholderConfidentialTextMap = {
  [TYPE_ISSUE]: __('Paste confidential issue link'),
  [issuableTypesMap.EPIC]: __('Paste confidential epic link'),
  [issuableTypesMap.MERGE_REQUEST]: __('Enter merge request URLs'),
};

export const relatedIssuesRemoveErrorMap = {
  [TYPE_ISSUE]: __('An error occurred while removing issues.'),
  [issuableTypesMap.EPIC]: __('An error occurred while removing epics.'),
};

export const pathIndeterminateErrorMap = {
  [TYPE_ISSUE]: __('We could not determine the path to remove the issue'),
  [issuableTypesMap.EPIC]: __('We could not determine the path to remove the epic'),
};

export const itemAddFailureTypesMap = {
  NOT_FOUND: 'not_found',
  MAX_NUMBER_OF_CHILD_EPICS: 'conflict',
};

export const addRelatedIssueErrorMap = {
  [TYPE_ISSUE]: __('Issue cannot be found.'),
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
  [TYPE_ISSUE]: 'issues',
  [issuableTypesMap.INCIDENT]: 'issues',
  [issuableTypesMap.EPIC]: 'epic',
};

export const PathIdSeparator = {
  Epic: '&',
  Issue: '#',
};

export const issuablesBlockHeaderTextMap = {
  [TYPE_ISSUE]: __('Linked items'),
  [issuableTypesMap.INCIDENT]: __('Linked incidents or issues'),
  [issuableTypesMap.EPIC]: __('Linked epics'),
};

export const issuablesBlockHelpTextMap = {
  [TYPE_ISSUE]: __('Learn more about linking issues'),
  [issuableTypesMap.INCIDENT]: __('Learn more about linking issues and incidents'),
  [issuableTypesMap.EPIC]: __('Learn more about linking epics'),
};

export const issuablesBlockAddButtonTextMap = {
  [TYPE_ISSUE]: __('Add a related issue'),
  [issuableTypesMap.EPIC]: __('Add a related epic'),
};

export const issuablesFormCategoryHeaderTextMap = {
  [TYPE_ISSUE]: __('The current issue'),
  [issuableTypesMap.INCIDENT]: __('The current incident'),
  [issuableTypesMap.EPIC]: __('The current epic'),
};

export const issuablesFormInputTextMap = {
  [TYPE_ISSUE]: __('the following issues'),
  [issuableTypesMap.INCIDENT]: __('the following incidents or issues'),
  [issuableTypesMap.EPIC]: __('the following epics'),
};
