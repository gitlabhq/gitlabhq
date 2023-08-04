import events from 'test_fixtures/controller/users/activity.json';
import {
  EVENT_TYPE_APPROVED,
  EVENT_TYPE_EXPIRED,
  EVENT_TYPE_JOINED,
  EVENT_TYPE_LEFT,
  EVENT_TYPE_PUSHED,
  EVENT_TYPE_PRIVATE,
  EVENT_TYPE_MERGED,
  EVENT_TYPE_CLOSED,
  PUSH_EVENT_REF_TYPE_BRANCH,
  PUSH_EVENT_REF_TYPE_TAG,
  EVENT_TYPE_CREATED,
  TARGET_TYPE_ISSUE,
  TARGET_TYPE_MILESTONE,
  TARGET_TYPE_MERGE_REQUEST,
  TARGET_TYPE_WIKI,
  TARGET_TYPE_DESIGN,
  TARGET_TYPE_WORK_ITEM,
  WORK_ITEM_ISSUE_TYPE_TASK,
  WORK_ITEM_ISSUE_TYPE_INCIDENT,
} from '~/contribution_events/constants';

const findEventByAction = (action) => () => events.find((event) => event.action === action);
const findEventByActionAndTargetType = (action, targetType) => () =>
  events.find((event) => event.action === action && event.target?.type === targetType);
const findEventByActionAndIssueType = (action, issueType) => () =>
  events.find(
    (event) =>
      event.action === action &&
      event.target?.type === TARGET_TYPE_WORK_ITEM &&
      event.target.issue_type === issueType,
  );

export const eventApproved = findEventByAction(EVENT_TYPE_APPROVED);

export const eventExpired = findEventByAction(EVENT_TYPE_EXPIRED);

export const eventJoined = findEventByAction(EVENT_TYPE_JOINED);

export const eventLeft = findEventByAction(EVENT_TYPE_LEFT);

export const eventMerged = findEventByAction(EVENT_TYPE_MERGED);

const findPushEvent = ({
  isNew = false,
  isRemoved = false,
  refType = PUSH_EVENT_REF_TYPE_BRANCH,
  commitCount = 1,
} = {}) => () =>
  events.find(
    ({ action, ref, commit }) =>
      action === EVENT_TYPE_PUSHED &&
      ref.is_new === isNew &&
      ref.is_removed === isRemoved &&
      ref.type === refType &&
      commit.count === commitCount,
  );

export const eventPushedNewBranch = findPushEvent({ isNew: true });
export const eventPushedNewTag = findPushEvent({ isNew: true, refType: PUSH_EVENT_REF_TYPE_TAG });
export const eventPushedBranch = findPushEvent();
export const eventPushedTag = findPushEvent({ refType: PUSH_EVENT_REF_TYPE_TAG });
export const eventPushedRemovedBranch = findPushEvent({ isRemoved: true });
export const eventPushedRemovedTag = findPushEvent({
  isRemoved: true,
  refType: PUSH_EVENT_REF_TYPE_TAG,
});
export const eventBulkPushedBranch = findPushEvent({ commitCount: 5 });

export const eventPrivate = () => ({ ...events[0], action: EVENT_TYPE_PRIVATE });

export const eventCreated = findEventByAction(EVENT_TYPE_CREATED);

export const findCreatedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_CREATED, targetType);
export const findWorkItemCreatedEvent = (issueType) =>
  findEventByActionAndIssueType(EVENT_TYPE_CREATED, issueType);

export const eventProjectCreated = findCreatedEvent(undefined);
export const eventMilestoneCreated = findCreatedEvent(TARGET_TYPE_MILESTONE);
export const eventIssueCreated = findCreatedEvent(TARGET_TYPE_ISSUE);
export const eventMergeRequestCreated = findCreatedEvent(TARGET_TYPE_MERGE_REQUEST);
export const eventWikiPageCreated = findCreatedEvent(TARGET_TYPE_WIKI);
export const eventDesignCreated = findCreatedEvent(TARGET_TYPE_DESIGN);
export const eventTaskCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_TASK);
export const eventIncidentCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_INCIDENT);

export const eventClosed = findEventByAction(EVENT_TYPE_CLOSED);

export const findClosedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_CREATED, targetType);
export const findWorkItemClosedEvent = (issueType) =>
  findEventByActionAndIssueType(EVENT_TYPE_CLOSED, issueType);

export const eventMilestoneClosed = findClosedEvent(TARGET_TYPE_MILESTONE);
export const eventIssueClosed = findClosedEvent(TARGET_TYPE_ISSUE);
export const eventMergeRequestClosed = findClosedEvent(TARGET_TYPE_MERGE_REQUEST);
export const eventWikiPageClosed = findClosedEvent(TARGET_TYPE_WIKI);
export const eventDesignClosed = findClosedEvent(TARGET_TYPE_DESIGN);
export const eventTaskClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_TASK);
export const eventIncidentClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_INCIDENT);
