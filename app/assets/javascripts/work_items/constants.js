import { __, s__, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export const STATE_OPEN = 'OPEN';
export const STATE_CLOSED = 'CLOSED';

export const STATE_EVENT_REOPEN = 'REOPEN';
export const STATE_EVENT_CLOSE = 'CLOSE';

export const TRACKING_CATEGORY_SHOW = 'workItems:show';

export const WIDGET_TYPE_ASSIGNEES = 'ASSIGNEES';
export const WIDGET_TYPE_DESCRIPTION = 'DESCRIPTION';
export const WIDGET_TYPE_AWARD_EMOJI = 'AWARD_EMOJI';
export const WIDGET_TYPE_NOTIFICATIONS = 'NOTIFICATIONS';
export const WIDGET_TYPE_CURRENT_USER_TODOS = 'CURRENT_USER_TODOS';
export const WIDGET_TYPE_LABELS = 'LABELS';
export const WIDGET_TYPE_START_AND_DUE_DATE = 'START_AND_DUE_DATE';
export const WIDGET_TYPE_TIME_TRACKING = 'TIME_TRACKING';
export const WIDGET_TYPE_WEIGHT = 'WEIGHT';
export const WIDGET_TYPE_PARTICIPANTS = 'PARTICIPANTS';
export const WIDGET_TYPE_PROGRESS = 'PROGRESS';
export const WIDGET_TYPE_HIERARCHY = 'HIERARCHY';
export const WIDGET_TYPE_MILESTONE = 'MILESTONE';
export const WIDGET_TYPE_ITERATION = 'ITERATION';
export const WIDGET_TYPE_NOTES = 'NOTES';
export const WIDGET_TYPE_HEALTH_STATUS = 'HEALTH_STATUS';
export const WIDGET_TYPE_LINKED_ITEMS = 'LINKED_ITEMS';
export const WIDGET_TYPE_COLOR = 'COLOR';
export const WIDGET_TYPE_DESIGNS = 'DESIGNS';
export const WIDGET_TYPE_DEVELOPMENT = 'DEVELOPMENT';
export const WIDGET_TYPE_CRM_CONTACTS = 'CRM_CONTACTS';
export const WIDGET_TYPE_EMAIL_PARTICIPANTS = 'EMAIL_PARTICIPANTS';
export const WIDGET_TYPE_CUSTOM_FIELDS = 'CUSTOM_FIELDS';

export const WORK_ITEM_TYPE_ENUM_EPIC = 'EPIC';
export const WORK_ITEM_TYPE_ENUM_INCIDENT = 'INCIDENT';
export const WORK_ITEM_TYPE_ENUM_ISSUE = 'ISSUE';
export const WORK_ITEM_TYPE_ENUM_KEY_RESULT = 'KEY_RESULT';
export const WORK_ITEM_TYPE_ENUM_OBJECTIVE = 'OBJECTIVE';
export const WORK_ITEM_TYPE_ENUM_REQUIREMENTS = 'REQUIREMENT';
export const WORK_ITEM_TYPE_ENUM_TASK = 'TASK';
export const WORK_ITEM_TYPE_ENUM_TEST_CASE = 'TEST_CASE';
export const WORK_ITEM_TYPE_ENUM_TICKET = 'TICKET';

export const WORK_ITEM_TYPE_VALUE_EPIC = 'Epic';
export const WORK_ITEM_TYPE_VALUE_INCIDENT = 'Incident';
export const WORK_ITEM_TYPE_VALUE_ISSUE = 'Issue';
export const WORK_ITEM_TYPE_VALUE_KEY_RESULT = 'Key Result';
export const WORK_ITEM_TYPE_VALUE_OBJECTIVE = 'Objective';
export const WORK_ITEM_TYPE_VALUE_REQUIREMENTS = 'Requirement';
export const WORK_ITEM_TYPE_VALUE_TASK = 'Task';
export const WORK_ITEM_TYPE_VALUE_TEST_CASE = 'Test Case';
export const WORK_ITEM_TYPE_VALUE_TICKET = 'Ticket';

export const SEARCH_DEBOUNCE = 500;

export const i18n = {
  fetchErrorTitle: s__('WorkItem|Work item not found'),
  fetchError: s__(
    "WorkItem|This work item is not available. It either doesn't exist or you don't have permission to view it.",
  ),
  updateError: s__('WorkItem|Something went wrong while updating the work item. Please try again.'),
  addDesignEmptyState: s__('DesignManagement|Drag images here to add designs.'),
};

export const I18N_WORK_ITEM_ERROR_FETCHING_LABELS = s__(
  'WorkItem|Something went wrong when fetching labels. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_FETCHING_CRM_CONTACTS = s__(
  'WorkItem|Something went wrong when fetching CRM contacts. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_FETCHING_TYPES = s__(
  'WorkItem|Something went wrong when fetching work item types. Please try again',
);
export const I18N_WORK_ITEM_ERROR_CREATING = s__(
  'WorkItem|Something went wrong when creating %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_UPDATING = s__(
  'WorkItem|Something went wrong while updating the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_CONVERTING = s__(
  'WorkItem|Something went wrong while promoting the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_DELETING = s__(
  'WorkItem|Something went wrong when deleting the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_DELETE = s__('WorkItem|Delete %{workItemType}');
export const I18N_WORK_ITEM_ARE_YOU_SURE_DELETE = s__(
  'WorkItem|Are you sure you want to delete the %{workItemType}? This action cannot be reversed.',
);
export const I18N_WORK_ITEM_ARE_YOU_SURE_DELETE_HIERARCHY = s__(
  'WorkItem|Delete this %{workItemType} and release all child items? This action cannot be reversed.',
);
export const I18N_WORK_ITEM_CREATED = s__('WorkItem|%{workItemType} created');
export const I18N_WORK_ITEM_DELETED = s__('WorkItem|%{workItemType} deleted');

export const I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR = s__(
  'WorkItem|Something went wrong when fetching iterations. Please try again.',
);

export const I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR = s__(
  'WorkItem|Something went wrong while fetching work item award emojis. Please try again.',
);

export const I18N_NEW_WORK_ITEM_BUTTON_LABEL = s__('WorkItem|New %{workItemType}');
export const I18N_WORK_ITEM_CREATE_BUTTON_LABEL = s__('WorkItem|Create %{workItemType}');
export const I18N_WORK_ITEM_NEW_RELATED_ITEM = s__('WorkItem|New related %{workItemType}');
export const I18N_WORK_ITEM_ADD_BUTTON_LABEL = s__('WorkItem|Add %{workItemType}');
export const I18N_WORK_ITEM_ADD_MULTIPLE_BUTTON_LABEL = s__('WorkItem|Add %{workItemType}s');
export const I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER = s__(
  'WorkItem|Search existing items, paste URL, or enter reference ID',
);
export const I18N_WORK_ITEM_SEARCH_ERROR = s__(
  'WorkItem|Something went wrong while fetching the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_NO_MATCHES_FOUND = s__('WorkItem|No matches found');
export const I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL = s__(
  'WorkItem|This %{workItemType} is confidential and should only be visible to team members with at least the Planner role',
);
export const I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP = s__(
  'WorkItem|A non-confidential %{workItemType} cannot be assigned to a confidential parent %{parentWorkItemType}.',
);

export const I18N_WORK_ITEM_ERROR_COPY_REFERENCE = s__(
  'WorkItem|Something went wrong while copying the %{workItemType} reference. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_COPY_EMAIL = s__(
  'WorkItem|Something went wrong while copying the %{workItemType} email address. Please try again.',
);

export const I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL = s__(
  'WorkItem|Copy %{workItemType} email address',
);

export const MAX_WORK_ITEMS = 10;

export const I18N_MAX_WORK_ITEMS_ERROR_MESSAGE = sprintf(
  s__('WorkItem|Only %{MAX_WORK_ITEMS} items can be added at a time.'),
  { MAX_WORK_ITEMS },
);
export const I18N_MAX_WORK_ITEMS_NOTE_LABEL = sprintf(
  s__('WorkItem|Add up to %{MAX_WORK_ITEMS} items at a time.'),
  { MAX_WORK_ITEMS },
);

export const I18N_WORK_ITEM_CHANGE_TYPE_PARENT_ERROR = s__(
  'WorkItem|Parent item type %{parentWorkItemType} is not supported on %{workItemType}. Remove the parent item to change type.',
);

export const I18N_WORK_ITEM_CHANGE_TYPE_CHILD_ERROR = s__(
  'WorkItem|%{workItemType} does not support the %{childItemType} child item types. Remove child items to change type.',
);

export const I18N_WORK_ITEM_CHANGE_TYPE_MISSING_FIELDS_ERROR = s__(
  'WorkItem|Some fields are not present in %{workItemType}. If you change type now, this information will be lost.',
);

export const sprintfWorkItem = (msg, workItemTypeArg, parentWorkItemType = '') => {
  const workItemType = workItemTypeArg || s__('WorkItem|item');
  return capitalizeFirstCharacter(
    sprintf(msg, {
      workItemType: workItemType.toLocaleLowerCase(),
      parentWorkItemType: parentWorkItemType.toLocaleLowerCase(),
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
    value: WORK_ITEM_TYPE_VALUE_INCIDENT,
  },
  [WORK_ITEM_TYPE_ENUM_ISSUE]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Issue'),
    value: WORK_ITEM_TYPE_VALUE_ISSUE,
    routeParamName: 'issues',
  },
  [WORK_ITEM_TYPE_ENUM_TASK]: {
    icon: `issue-type-task`,
    name: s__('WorkItem|Task'),
    value: WORK_ITEM_TYPE_VALUE_TASK,
  },
  [WORK_ITEM_TYPE_ENUM_TEST_CASE]: {
    icon: `issue-type-test-case`,
    name: s__('WorkItem|Test case'),
    value: WORK_ITEM_TYPE_VALUE_TEST_CASE,
  },
  [WORK_ITEM_TYPE_ENUM_REQUIREMENTS]: {
    icon: `issue-type-requirements`,
    name: s__('WorkItem|Requirements'),
    value: WORK_ITEM_TYPE_VALUE_REQUIREMENTS,
  },
  [WORK_ITEM_TYPE_ENUM_OBJECTIVE]: {
    icon: `issue-type-objective`,
    name: s__('WorkItem|Objective'),
    value: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  },
  [WORK_ITEM_TYPE_ENUM_KEY_RESULT]: {
    icon: `issue-type-keyresult`,
    name: s__('WorkItem|Key result'),
    value: WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  },
  [WORK_ITEM_TYPE_ENUM_EPIC]: {
    icon: `epic`,
    name: s__('WorkItem|Epic'),
    value: WORK_ITEM_TYPE_VALUE_EPIC,
    routeParamName: 'epics',
  },
};

export const WORK_ITEM_TYPE_VALUE_MAP = {
  [WORK_ITEM_TYPE_VALUE_EPIC]: WORK_ITEM_TYPE_ENUM_EPIC,
  [WORK_ITEM_TYPE_VALUE_INCIDENT]: WORK_ITEM_TYPE_ENUM_INCIDENT,
  [WORK_ITEM_TYPE_VALUE_ISSUE]: WORK_ITEM_TYPE_ENUM_ISSUE,
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  [WORK_ITEM_TYPE_VALUE_REQUIREMENTS]: WORK_ITEM_TYPE_ENUM_REQUIREMENTS,
  [WORK_ITEM_TYPE_VALUE_TASK]: WORK_ITEM_TYPE_ENUM_TASK,
  [WORK_ITEM_TYPE_VALUE_TEST_CASE]: WORK_ITEM_TYPE_ENUM_TEST_CASE,
  [WORK_ITEM_TYPE_VALUE_TICKET]: WORK_ITEM_TYPE_ENUM_TICKET,
};

export const WORK_ITEMS_TREE_TEXT = {
  title: s__('WorkItem|Child items'),
  empty: s__(
    'WorkItem|No child items are currently assigned. Use child items to break down work into smaller parts.',
  ),
};

export const FORM_TYPES = {
  create: 'create',
  add: 'add',
  [WORK_ITEM_TYPE_ENUM_OBJECTIVE]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Objective'),
  },
};

export const DEFAULT_PAGE_SIZE_NOTES = 20; // Set to 20 to not exceed query complexity
export const DEFAULT_PAGE_SIZE_EMOJIS = 100;
export const DEFAULT_PAGE_SIZE_CHILD_ITEMS = 50;

export const WORK_ITEM_NOTES_SORT_ORDER_KEY = 'sort_direction_work_item';

export const WORK_ITEM_NOTES_FILTER_ALL_NOTES = 'ALL_NOTES';
export const WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS = 'ONLY_COMMENTS';
export const WORK_ITEM_NOTES_FILTER_ONLY_HISTORY = 'ONLY_HISTORY';

export const WORK_ITEM_NOTES_FILTER_KEY = 'filter_key_work_item';

export const WORK_ITEM_ACTIVITY_FILTER_OPTIONS = [
  {
    value: WORK_ITEM_NOTES_FILTER_ALL_NOTES,
    text: s__('WorkItem|All activity'),
  },
  {
    value: WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
    text: s__('WorkItem|Comments only'),
  },
  {
    value: WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
    text: s__('WorkItem|History only'),
  },
];

export const WORK_ITEM_ACTIVITY_SORT_OPTIONS = [
  { value: 'desc', text: __('Newest first') },
  { value: 'asc', text: __('Oldest first') },
];

export const TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION = 'confidentiality-toggle-action';
export const TEST_ID_NOTIFICATIONS_TOGGLE_FORM = 'notifications-toggle-form';
export const TEST_ID_DELETE_ACTION = 'delete-action';
export const TEST_ID_PROMOTE_ACTION = 'promote-action';
export const TEST_ID_CHANGE_TYPE_ACTION = 'change-type-action';
export const TEST_ID_LOCK_ACTION = 'lock-action';
export const TEST_ID_COPY_REFERENCE_ACTION = 'copy-reference-action';
export const TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION = 'copy-create-note-email-action';
export const TEST_ID_TOGGLE_ACTION = 'state-toggle-action';
export const TEST_ID_REPORT_ABUSE = 'report-abuse-action';
export const TEST_ID_NEW_RELATED_WORK_ITEM = 'new-related-work-item';

export const TODO_ADD_ICON = 'todo-add';
export const TODO_DONE_ICON = 'todo-done';
export const TODO_DONE_STATE = 'done';
export const TODO_PENDING_STATE = 'pending';

export const WORK_ITEM_TO_ISSUABLE_MAP = {
  [WIDGET_TYPE_ASSIGNEES]: 'assignees',
  [WIDGET_TYPE_LABELS]: 'labels',
  [WIDGET_TYPE_MILESTONE]: 'milestone',
  [WIDGET_TYPE_WEIGHT]: 'weight',
  [WIDGET_TYPE_ITERATION]: 'iteration',
  [WIDGET_TYPE_START_AND_DUE_DATE]: 'dueDate',
  [WIDGET_TYPE_HEALTH_STATUS]: 'healthStatus',
  [WIDGET_TYPE_AWARD_EMOJI]: 'awardEmoji',
  [WIDGET_TYPE_TIME_TRACKING]: 'timeEstimate',
  [WIDGET_TYPE_COLOR]: 'color',
};

export const LINKED_CATEGORIES_MAP = {
  RELATES_TO: 'relates_to',
  IS_BLOCKED_BY: 'is_blocked_by',
  BLOCKS: 'blocks',
};

export const RELATIONSHIP_TYPE_ENUM = {
  relates_to: 'RELATED',
  blocks: 'BLOCKS',
  is_blocked_by: 'BLOCKED_BY',
};

export const LINKED_ITEM_TYPE_VALUE = {
  RELATED: 'RELATED',
  BLOCKED_BY: 'BLOCKED_BY',
  BLOCKS: 'BLOCKS',
};

export const LINK_ITEM_FORM_HEADER_LABEL = {
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: s__('WorkItem|The current objective'),
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: s__('WorkItem|The current key result'),
  [WORK_ITEM_TYPE_VALUE_TASK]: s__('WorkItem|The current task'),
};

export const LINKED_ITEMS_ANCHOR = 'linkeditems';
export const CHILD_ITEMS_ANCHOR = 'childitems';
export const TASKS_ANCHOR = 'tasks';
export const DEVELOPMENT_ITEMS_ANCHOR = 'developmentitems';

export const ISSUABLE_EPIC = 'issue-type-epic';

export const EPIC_COLORS = [
  { '#1068bf': s__('WorkItem|Blue') },
  { '#217645': s__('WorkItem|Forest green') },
  { '#c91c00': s__('WorkItem|Dark red') },
  { '#9e5400': s__('WorkItem|Coffee') },
  { '#694cc0': s__('WorkItem|Purple') },
  { '#de198f': s__('WorkItem|Magenta') },
  { '#2e90a5': s__('WorkItem|Teal') },
  { '#55aafe': s__('WorkItem|Light blue') },
  { '#4dd787': s__('WorkItem|Mint green') },
  { '#f17763': s__('WorkItem|Rose') },
  { '#f3ad5d': s__('WorkItem|Apricot') },
  { '#b7a0fd': s__('WorkItem|Lavender') },
  { '#fd8cd0': s__('WorkItem|Pink') },
  { '#6cd3ea': s__('WorkItem|Aqua') },
];

export const DEFAULT_EPIC_COLORS = '#1068bf';

export const MAX_FREQUENT_PROJECTS = 3;
export const CREATE_NEW_WORK_ITEM_MODAL = 'create_new_work_item_modal';
export const RELATED_ITEM_ID_URL_QUERY_PARAM = 'related_item_id';

export const WORK_ITEM_REFERENCE_CHAR = '#';

export const NEW_WORK_ITEM_IID = 'new-work-item-iid';

export const NEW_WORK_ITEM_GID = 'gid://gitlab/WorkItem/new';

export const NEW_EPIC_FEEDBACK_PROMPT_EXPIRY = '2024-12-31';
export const FEATURE_NAME = 'work_item_epic_feedback';

export const DETAIL_VIEW_QUERY_PARAM_NAME = 'show';
export const ROUTES = {
  index: 'workItemList',
  workItem: 'workItem',
  new: 'new',
  design: 'design',
};

export const WORK_ITEM_TYPE_ROUTE_WORK_ITEM = 'work_items';
export const WORK_ITEM_TYPE_ROUTE_ISSUE = 'issues';
export const WORK_ITEM_TYPE_ROUTE_EPIC = 'epics';

export const WORK_ITEM_BASE_ROUTE_MAP = {
  [WORK_ITEM_TYPE_ROUTE_WORK_ITEM]: null,
  [WORK_ITEM_TYPE_ROUTE_ISSUE]: WORK_ITEM_TYPE_ENUM_ISSUE,
  [WORK_ITEM_TYPE_ROUTE_EPIC]: WORK_ITEM_TYPE_ENUM_EPIC,
};

export const WORKITEM_LINKS_SHOWLABELS_LOCALSTORAGEKEY = 'workItemLinks.showLabels';
export const WORKITEM_TREE_SHOWLABELS_LOCALSTORAGEKEY = 'workItemTree.showLabels';
export const WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY = 'workItemTree.showClosed';
export const WORKITEM_RELATIONSHIPS_SHOWLABELS_LOCALSTORAGEKEY = 'workItemRelationships.showLabels';
export const WORKITEM_RELATIONSHIPS_SHOWCLOSED_LOCALSTORAGEKEY = 'workItemRelationships.showClosed';

export const INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION = Symbol(
  'injection:prevent-router-navigation',
);

export const WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE = 'source';
export const WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_BRANCH = 'branch';

export const BASE_ALLOWED_CREATE_TYPES = [
  WORK_ITEM_TYPE_VALUE_INCIDENT,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  WORK_ITEM_TYPE_VALUE_TASK,
];

export const ALLOWED_CONVERSION_TYPES = [
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_TASK,
  WORK_ITEM_TYPE_VALUE_ISSUE,
];

export const WORK_ITEM_TYPE_NAME_MAP = {
  [WORK_ITEM_TYPE_VALUE_EPIC]: s__('WorkItem|Epic'),
  [WORK_ITEM_TYPE_VALUE_INCIDENT]: s__('WorkItem|Incident'),
  [WORK_ITEM_TYPE_VALUE_ISSUE]: s__('WorkItem|Issue'),
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: s__('WorkItem|Key result'),
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: s__('WorkItem|Objective'),
  [WORK_ITEM_TYPE_VALUE_REQUIREMENTS]: s__('WorkItem|Requirement'),
  [WORK_ITEM_TYPE_VALUE_TASK]: s__('WorkItem|Task'),
  [WORK_ITEM_TYPE_VALUE_TEST_CASE]: s__('WorkItem|Test case'),
  [WORK_ITEM_TYPE_VALUE_TICKET]: s__('WorkItem|Ticket'),
};

export const WORK_ITEM_TYPE_NAME_LOWERCASE_MAP = {
  [WORK_ITEM_TYPE_VALUE_EPIC]: s__('WorkItem|epic'),
  [WORK_ITEM_TYPE_VALUE_INCIDENT]: s__('WorkItem|incident'),
  [WORK_ITEM_TYPE_VALUE_ISSUE]: s__('WorkItem|issue'),
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: s__('WorkItem|key result'),
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: s__('WorkItem|objective'),
  [WORK_ITEM_TYPE_VALUE_REQUIREMENTS]: s__('WorkItem|requirement'),
  [WORK_ITEM_TYPE_VALUE_TASK]: s__('WorkItem|task'),
  [WORK_ITEM_TYPE_VALUE_TEST_CASE]: s__('WorkItem|test case'),
  [WORK_ITEM_TYPE_VALUE_TICKET]: s__('WorkItem|ticket'),
};

export const WORK_ITEM_WIDGETS_NAME_MAP = {
  [WIDGET_TYPE_ASSIGNEES]: s__('WorkItem|Assignees'),
  [WIDGET_TYPE_DESCRIPTION]: s__('WorkItem|Description'),
  [WIDGET_TYPE_AWARD_EMOJI]: s__('WorkItem|Emoji reactions'),
  [WIDGET_TYPE_NOTIFICATIONS]: s__('WorkItem|Notifications'),
  [WIDGET_TYPE_CURRENT_USER_TODOS]: s__('WorkItem|To-do item'),
  [WIDGET_TYPE_LABELS]: s__('WorkItem|Labels'),
  [WIDGET_TYPE_START_AND_DUE_DATE]: s__('WorkItem|Dates'),
  [WIDGET_TYPE_TIME_TRACKING]: s__('WorkItem|Time tracking'),
  [WIDGET_TYPE_WEIGHT]: s__('WorkItem|Weight'),
  [WIDGET_TYPE_PARTICIPANTS]: s__('WorkItem|Participants'),
  [WIDGET_TYPE_EMAIL_PARTICIPANTS]: s__('WorkItem|Email participants'),
  [WIDGET_TYPE_PROGRESS]: s__('WorkItem|Progress'),
  [WIDGET_TYPE_HIERARCHY]: s__('WorkItem|Child items'),
  [WIDGET_TYPE_MILESTONE]: s__('WorkItem|Milestone'),
  [WIDGET_TYPE_ITERATION]: s__('WorkItem|Iteration'),
  [WIDGET_TYPE_NOTES]: s__('WorkItem|Comments and threads'),
  [WIDGET_TYPE_HEALTH_STATUS]: s__('WorkItem|Health status'),
  [WIDGET_TYPE_LINKED_ITEMS]: s__('WorkItem|Linked items'),
  [WIDGET_TYPE_COLOR]: s__('WorkItem|Color'),
  [WIDGET_TYPE_DESIGNS]: s__('WorkItem|Designs'),
  [WIDGET_TYPE_DEVELOPMENT]: s__('WorkItem|Development'),
  [WIDGET_TYPE_CRM_CONTACTS]: s__('WorkItem|Contacts'),
};

export const CUSTOM_FIELDS_TYPE_NUMBER = 'NUMBER';
export const CUSTOM_FIELDS_TYPE_TEXT = 'TEXT';
export const CUSTOM_FIELDS_TYPE_SINGLE_SELECT = 'SINGLE_SELECT';
export const CUSTOM_FIELDS_TYPE_MULTI_SELECT = 'MULTI_SELECT';
