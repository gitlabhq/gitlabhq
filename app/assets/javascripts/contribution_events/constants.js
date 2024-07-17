import { s__ } from '~/locale';
import {
  ISSUE_NOTEABLE_TYPE,
  MERGE_REQUEST_NOTEABLE_TYPE,
  DESIGN_NOTEABLE_TYPE,
  COMMIT_NOTEABLE_TYPE,
} from '~/notes/constants';

// From app/models/event.rb#L16
export const EVENT_TYPE_CREATED = 'created';
export const EVENT_TYPE_UPDATED = 'updated';
export const EVENT_TYPE_CLOSED = 'closed';
export const EVENT_TYPE_REOPENED = 'reopened';
export const EVENT_TYPE_PUSHED = 'pushed';
export const EVENT_TYPE_COMMENTED = 'commented';
export const EVENT_TYPE_MERGED = 'merged';
export const EVENT_TYPE_JOINED = 'joined';
export const EVENT_TYPE_LEFT = 'left';
export const EVENT_TYPE_DESTROYED = 'destroyed';
export const EVENT_TYPE_EXPIRED = 'expired';
export const EVENT_TYPE_APPROVED = 'approved';
export const EVENT_TYPE_PRIVATE = 'private';

// From app/models/push_event_payload.rb#L22
export const PUSH_EVENT_REF_TYPE_BRANCH = 'branch';
export const PUSH_EVENT_REF_TYPE_TAG = 'tag';

export const RESOURCE_PARENT_TYPE_PROJECT = 'project';

// From app/models/event.rb#L39
export const TARGET_TYPE_ISSUE = 'Issue';
export const TARGET_TYPE_MILESTONE = 'Milestone';
export const TARGET_TYPE_MERGE_REQUEST = 'MergeRequest';
export const TARGET_TYPE_WIKI = 'WikiPage::Meta';
export const TARGET_TYPE_DESIGN = 'DesignManagement::Design';
export const TARGET_TYPE_WORK_ITEM = 'WorkItem';

// From app/models/work_items/type.rb#L28
export const WORK_ITEM_ISSUE_TYPE_ISSUE = 'issue';
export const WORK_ITEM_ISSUE_TYPE_TASK = 'task';
export const WORK_ITEM_ISSUE_TYPE_INCIDENT = 'incident';

export const TYPE_FALLBACK = 'fallback';

export const EVENT_CREATED_I18N = Object.freeze({
  [RESOURCE_PARENT_TYPE_PROJECT]: s__('ContributionEvent|Created project %{resourceParentLink}.'),
  [TARGET_TYPE_MILESTONE]: s__(
    'ContributionEvent|Opened milestone %{targetLink} in %{resourceParentLink}.',
  ),
  [TARGET_TYPE_MERGE_REQUEST]: s__(
    'ContributionEvent|Opened merge request %{targetLink} in %{resourceParentLink}.',
  ),
  [TARGET_TYPE_WIKI]: s__(
    'ContributionEvent|Created wiki page %{targetLink} in %{resourceParentLink}.',
  ),
  [TARGET_TYPE_DESIGN]: s__(
    'ContributionEvent|Added design %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_ISSUE]: s__(
    'ContributionEvent|Opened issue %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_TASK]: s__(
    'ContributionEvent|Opened task %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_INCIDENT]: s__(
    'ContributionEvent|Opened incident %{targetLink} in %{resourceParentLink}.',
  ),
  [TYPE_FALLBACK]: s__('ContributionEvent|Created resource.'),
});

export const EVENT_CLOSED_I18N = Object.freeze({
  [TARGET_TYPE_MILESTONE]: s__(
    'ContributionEvent|Closed milestone %{targetLink} in %{resourceParentLink}.',
  ),
  [TARGET_TYPE_MERGE_REQUEST]: s__(
    'ContributionEvent|Closed merge request %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_ISSUE]: s__(
    'ContributionEvent|Closed issue %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_TASK]: s__(
    'ContributionEvent|Closed task %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_INCIDENT]: s__(
    'ContributionEvent|Closed incident %{targetLink} in %{resourceParentLink}.',
  ),
  [TYPE_FALLBACK]: s__('ContributionEvent|Closed resource.'),
});

export const EVENT_REOPENED_I18N = Object.freeze({
  [TARGET_TYPE_MILESTONE]: s__(
    'ContributionEvent|Reopened milestone %{targetLink} in %{resourceParentLink}.',
  ),
  [TARGET_TYPE_MERGE_REQUEST]: s__(
    'ContributionEvent|Reopened merge request %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_ISSUE]: s__(
    'ContributionEvent|Reopened issue %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_TASK]: s__(
    'ContributionEvent|Reopened task %{targetLink} in %{resourceParentLink}.',
  ),
  [WORK_ITEM_ISSUE_TYPE_INCIDENT]: s__(
    'ContributionEvent|Reopened incident %{targetLink} in %{resourceParentLink}.',
  ),
  [TYPE_FALLBACK]: s__('ContributionEvent|Reopened resource.'),
});

export const EVENT_COMMENTED_I18N = Object.freeze({
  [ISSUE_NOTEABLE_TYPE]: s__(
    'ContributionEvent|Commented on issue %{noteableLink} in %{resourceParentLink}.',
  ),
  [MERGE_REQUEST_NOTEABLE_TYPE]: s__(
    'ContributionEvent|Commented on merge request %{noteableLink} in %{resourceParentLink}.',
  ),
  [DESIGN_NOTEABLE_TYPE]: s__(
    'ContributionEvent|Commented on design %{noteableLink} in %{resourceParentLink}.',
  ),
  [COMMIT_NOTEABLE_TYPE]: s__(
    'ContributionEvent|Commented on commit %{noteableLink} in %{resourceParentLink}.',
  ),
  [TYPE_FALLBACK]: s__('ContributionEvent|Commented on %{noteableLink}.'),
});

export const EVENT_COMMENTED_SNIPPET_I18N = Object.freeze({
  [RESOURCE_PARENT_TYPE_PROJECT]: s__(
    'ContributionEvent|Commented on snippet %{noteableLink} in %{resourceParentLink}.',
  ),
  [TYPE_FALLBACK]: s__('ContributionEvent|Commented on snippet %{noteableLink}.'),
});

export const EVENT_UPDATED_I18N = Object.freeze({
  [TARGET_TYPE_DESIGN]: s__(
    'ContributionEvent|Updated design %{targetLink} in %{resourceParentLink}.',
  ),
  [TARGET_TYPE_WIKI]: s__(
    'ContributionEvent|Updated wiki page %{targetLink} in %{resourceParentLink}.',
  ),
  [TYPE_FALLBACK]: s__('ContributionEvent|Updated resource.'),
});

export const EVENT_DESTROYED_I18N = Object.freeze({
  [TARGET_TYPE_DESIGN]: s__('ContributionEvent|Archived design in %{resourceParentLink}.'),
  [TARGET_TYPE_WIKI]: s__('ContributionEvent|Deleted wiki page in %{resourceParentLink}.'),
  [TARGET_TYPE_MILESTONE]: s__('ContributionEvent|Deleted milestone in %{resourceParentLink}.'),
  [TYPE_FALLBACK]: s__('ContributionEvent|Deleted resource.'),
});

export const EVENT_CLOSED_ICONS = Object.freeze({
  [WORK_ITEM_ISSUE_TYPE_ISSUE]: 'issue-closed',
  [TARGET_TYPE_MERGE_REQUEST]: 'merge-request-close',
  [TYPE_FALLBACK]: 'status_closed',
});

export const EVENT_REOPENED_ICONS = Object.freeze({
  [TARGET_TYPE_MERGE_REQUEST]: 'merge-request',
  [TYPE_FALLBACK]: 'status_open',
});

export const EVENT_DESTROYED_ICONS = Object.freeze({
  [TARGET_TYPE_DESIGN]: 'archive',
  [TYPE_FALLBACK]: 'remove',
});
