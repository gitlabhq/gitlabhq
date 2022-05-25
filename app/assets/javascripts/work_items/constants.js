import { s__ } from '~/locale';

export const STATE_OPEN = 'OPEN';
export const STATE_CLOSED = 'CLOSED';

export const STATE_EVENT_REOPEN = 'REOPEN';
export const STATE_EVENT_CLOSE = 'CLOSE';

export const i18n = {
  fetchError: s__('WorkItem|Something went wrong when fetching the work item. Please try again.'),
  updateError: s__('WorkItem|Something went wrong while updating the work item. Please try again.'),
};

export const DEFAULT_MODAL_TYPE = 'Task';

export const WIDGET_TYPE_ASSIGNEE = 'ASSIGNEES';
