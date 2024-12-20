import { invert } from 'lodash';
import { s__, __, sprintf } from '~/locale';

export const defaultEpicSort = 'TITLE_ASC';

export const epicIidPattern = /^&(?<iid>\d+)$/;

export const dateTypes = {
  start: 'startDate',
  due: 'dueDate',
};

export const dateFields = {
  [dateTypes.start]: {
    isDateFixed: 'startDateIsFixed',
    dateFixed: 'startDateFixed',
    dateFromMilestones: 'startDateFromMilestones',
  },
  [dateTypes.due]: {
    isDateFixed: 'dueDateIsFixed',
    dateFixed: 'dueDateFixed',
    dateFromMilestones: 'dueDateFromMilestones',
  },
};

export const Tracking = {
  editEvent: 'click_edit_button',
  rightSidebarLabel: 'right_sidebar',
};

export const noAttributeId = null;

export const IssuableAttributeType = {
  Milestone: 'milestone',
};

export const LocalizedIssuableAttributeType = {
  Milestone: s__('Issuable|milestone'),
};

export const IssuableAttributeTypeKeyMap = invert(IssuableAttributeType);

export const IssuableAttributeState = {
  [IssuableAttributeType.Milestone]: 'active',
};

export const todoMutationTypes = {
  create: 'create',
  markDone: 'mark-done',
};

export function dropdowni18nText(issuableAttribute, issuableType) {
  return {
    noAttribute: sprintf(s__('DropdownWidget|No %{issuableAttribute}'), {
      issuableAttribute,
    }),
    assignAttribute: sprintf(s__('DropdownWidget|Select %{issuableAttribute}'), {
      issuableAttribute,
    }),
    noAttributesFound: sprintf(s__('DropdownWidget|No %{issuableAttribute} found'), {
      issuableAttribute,
    }),
    updateError: sprintf(
      s__(
        'DropdownWidget|Failed to set %{issuableAttribute} on this %{issuableType}. Please try again.',
      ),
      { issuableAttribute, issuableType },
    ),
    listFetchError: sprintf(
      s__(
        'DropdownWidget|Failed to fetch the %{issuableAttribute} for this %{issuableType}. Please try again.',
      ),
      { issuableAttribute, issuableType },
    ),
    currentFetchError: sprintf(
      s__(
        'DropdownWidget|An error occurred while fetching the assigned %{issuableAttribute} of the selected %{issuableType}.',
      ),
      { issuableAttribute, issuableType },
    ),
    noPermissionToView: sprintf(
      s__("DropdownWidget|You don't have permission to view this %{issuableAttribute}."),
      { issuableAttribute },
    ),
    editConfirmation: sprintf(
      s__(
        'DropdownWidget|You do not have permission to view the currently assigned %{issuableAttribute} and will not be able to choose it again if you reassign it.',
      ),
      {
        issuableAttribute,
      },
    ),
    editConfirmationCta: sprintf(s__('DropdownWidget|Edit %{issuableAttribute}'), {
      issuableAttribute,
    }),
    editConfirmationCancel: s__('DropdownWidget|Cancel'),
  };
}

export const statusDropdownOptions = [
  {
    text: __('Open'),
    value: 'reopen',
  },
  {
    text: __('Closed'),
    value: 'close',
  },
];

export const subscriptionsDropdownOptions = [
  {
    text: __('Subscribe'),
    value: 'subscribe',
  },
  {
    text: __('Unsubscribe'),
    value: 'unsubscribe',
  },
];

export const INCIDENT_SEVERITY = {
  CRITICAL: {
    value: 'CRITICAL',
    icon: 'critical',
    label: s__('IncidentManagement|Critical - S1'),
  },
  HIGH: {
    value: 'HIGH',
    icon: 'high',
    label: s__('IncidentManagement|High - S2'),
  },
  MEDIUM: {
    value: 'MEDIUM',
    icon: 'medium',
    label: s__('IncidentManagement|Medium - S3'),
  },
  LOW: {
    value: 'LOW',
    icon: 'low',
    label: s__('IncidentManagement|Low - S4'),
  },
  UNKNOWN: {
    value: 'UNKNOWN',
    icon: 'unknown',
    label: s__('IncidentManagement|Unknown'),
  },
};

export const MILESTONE_STATE = {
  ACTIVE: 'active',
  CLOSED: 'closed',
};

export const SEVERITY_I18N = {
  UPDATE_SEVERITY_ERROR: s__('SeverityWidget|There was an error while updating severity.'),
  TRY_AGAIN: __('Please try again'),
  EDIT: __('Edit'),
  SEVERITY: s__('SeverityWidget|Severity'),
  SEVERITY_VALUE: s__('SeverityWidget|Severity: %{severity}'),
};

export const STATUS_TRIGGERED = 'TRIGGERED';
export const STATUS_ACKNOWLEDGED = 'ACKNOWLEDGED';
export const STATUS_RESOLVED = 'RESOLVED';

export const STATUS_TRIGGERED_LABEL = s__('IncidentManagement|Triggered');
export const STATUS_ACKNOWLEDGED_LABEL = s__('IncidentManagement|Acknowledged');
export const STATUS_RESOLVED_LABEL = s__('IncidentManagement|Resolved');

export const STATUS_LABELS = {
  [STATUS_TRIGGERED]: STATUS_TRIGGERED_LABEL,
  [STATUS_ACKNOWLEDGED]: STATUS_ACKNOWLEDGED_LABEL,
  [STATUS_RESOLVED]: STATUS_RESOLVED_LABEL,
};

export const INCIDENTS_I18N = {
  fetchError: s__(
    'IncidentManagement|An error occurred while fetching the incident status. Please reload the page.',
  ),
  title: s__('IncidentManagement|Status'),
  updateError: s__(
    'IncidentManagement|An error occurred while updating the incident status. Please reload the page and try again.',
  ),
};
