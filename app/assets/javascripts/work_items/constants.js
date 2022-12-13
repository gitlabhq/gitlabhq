import { s__, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export const STATE_OPEN = 'OPEN';
export const STATE_CLOSED = 'CLOSED';

export const STATE_EVENT_REOPEN = 'REOPEN';
export const STATE_EVENT_CLOSE = 'CLOSE';

export const TRACKING_CATEGORY_SHOW = 'workItems:show';

export const TASK_TYPE_NAME = 'Task';

export const WIDGET_TYPE_ASSIGNEES = 'ASSIGNEES';
export const WIDGET_TYPE_DESCRIPTION = 'DESCRIPTION';
export const WIDGET_TYPE_LABELS = 'LABELS';
export const WIDGET_TYPE_START_AND_DUE_DATE = 'START_AND_DUE_DATE';
export const WIDGET_TYPE_WEIGHT = 'WEIGHT';
export const WIDGET_TYPE_HIERARCHY = 'HIERARCHY';
export const WIDGET_TYPE_MILESTONE = 'MILESTONE';
export const WIDGET_TYPE_ITERATION = 'ITERATION';

export const WORK_ITEM_TYPE_ENUM_INCIDENT = 'INCIDENT';
export const WORK_ITEM_TYPE_ENUM_ISSUE = 'ISSUE';
export const WORK_ITEM_TYPE_ENUM_TASK = 'TASK';
export const WORK_ITEM_TYPE_ENUM_TEST_CASE = 'TEST_CASE';
export const WORK_ITEM_TYPE_ENUM_REQUIREMENTS = 'REQUIREMENTS';
export const WORK_ITEM_TYPE_ENUM_OBJECTIVE = 'OBJECTIVE';
export const WORK_ITEM_TYPE_ENUM_KEY_RESULT = 'KEY_RESULT';

export const WORK_ITEM_TYPE_VALUE_ISSUE = 'Issue';
export const WORK_ITEM_TYPE_VALUE_OBJECTIVE = 'Objective';

export const i18n = {
  fetchErrorTitle: s__('WorkItem|Work item not found'),
  fetchError: s__(
    "WorkItem|This work item is not available. It either doesn't exist or you don't have permission to view it.",
  ),
  updateError: s__('WorkItem|Something went wrong while updating the work item. Please try again.'),
  confidentialTooltip: s__(
    'WorkItem|Only project members with at least the Reporter role, the author, and assignees can view or be notified about this task.',
  ),
};

export const I18N_WORK_ITEM_ERROR_FETCHING_LABELS = s__(
  'WorkItem|Something went wrong when fetching labels. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_CREATING = s__(
  'WorkItem|Something went wrong when creating %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_UPDATING = s__(
  'WorkItem|Something went wrong while updating the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_DELETING = s__(
  'WorkItem|Something went wrong when deleting the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_DELETE = s__('WorkItem|Delete %{workItemType}');
export const I18N_WORK_ITEM_ARE_YOU_SURE_DELETE = s__(
  'WorkItem|Are you sure you want to delete the %{workItemType}? This action cannot be reversed.',
);
export const I18N_WORK_ITEM_DELETED = s__('WorkItem|%{workItemType} deleted');

export const I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR = s__(
  'WorkItem|Something went wrong when fetching iterations. Please try again.',
);

export const I18N_WORK_ITEM_CREATE_BUTTON_LABEL = s__('WorkItem|Create %{workItemType}');
export const I18N_WORK_ITEM_ADD_BUTTON_LABEL = s__('WorkItem|Add %{workItemType}');
export const I18N_WORK_ITEM_ADD_MULTIPLE_BUTTON_LABEL = s__('WorkItem|Add %{workItemType}s');
export const I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER = s__(
  'WorkItem|Search existing %{workItemType}s',
);

export const sprintfWorkItem = (msg, workItemTypeArg) => {
  const workItemType = workItemTypeArg || s__('WorkItem|Work item');
  return capitalizeFirstCharacter(
    sprintf(msg, {
      workItemType: workItemType.toLocaleLowerCase(),
    }),
  );
};

export const WIDGET_ICONS = {
  TASK: 'issue-type-task',
};

export const WORK_ITEM_STATUS_TEXT = {
  CLOSED: s__('WorkItem|Closed'),
  OPEN: s__('WorkItem|Open'),
};

export const WORK_ITEMS_TYPE_MAP = {
  [WORK_ITEM_TYPE_ENUM_INCIDENT]: {
    icon: `issue-type-incident`,
    name: s__('WorkItem|Incident'),
  },
  [WORK_ITEM_TYPE_ENUM_ISSUE]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Issue'),
  },
  [WORK_ITEM_TYPE_ENUM_TASK]: {
    icon: `issue-type-task`,
    name: s__('WorkItem|Task'),
  },
  [WORK_ITEM_TYPE_ENUM_TEST_CASE]: {
    icon: `issue-type-test-case`,
    name: s__('WorkItem|Test case'),
  },
  [WORK_ITEM_TYPE_ENUM_REQUIREMENTS]: {
    icon: `issue-type-requirements`,
    name: s__('WorkItem|Requirements'),
  },
  [WORK_ITEM_TYPE_ENUM_OBJECTIVE]: {
    icon: `issue-type-objective`,
    name: s__('WorkItem|Objective'),
  },
  [WORK_ITEM_TYPE_ENUM_KEY_RESULT]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Key Result'),
  },
};

export const WORK_ITEMS_TREE_TEXT_MAP = {
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: {
    title: s__('WorkItem|Child objectives and key results'),
    empty: s__('WorkItem|No objectives or key results are currently assigned.'),
  },
};

export const WORK_ITEM_NAME_TO_ICON_MAP = {
  Issue: 'issue-type-issue',
  Task: 'issue-type-task',
  Objective: 'issue-type-objective',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  'Key Result': 'issue-type-key-result',
};

export const FORM_TYPES = {
  create: 'create',
  add: 'add',
  [WORK_ITEM_TYPE_ENUM_OBJECTIVE]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Objective'),
  },
};

export const DEFAULT_PAGE_SIZE_ASSIGNEES = 10;
