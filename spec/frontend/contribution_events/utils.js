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
  EVENT_TYPE_REOPENED,
  EVENT_TYPE_COMMENTED,
  EVENT_TYPE_UPDATED,
  EVENT_TYPE_DESTROYED,
  PUSH_EVENT_REF_TYPE_BRANCH,
  PUSH_EVENT_REF_TYPE_TAG,
  EVENT_TYPE_CREATED,
  TARGET_TYPE_ISSUE,
  TARGET_TYPE_MILESTONE,
  TARGET_TYPE_MERGE_REQUEST,
  TARGET_TYPE_WIKI,
  TARGET_TYPE_DESIGN,
  WORK_ITEM_ISSUE_TYPE_ISSUE,
  WORK_ITEM_ISSUE_TYPE_TASK,
  WORK_ITEM_ISSUE_TYPE_INCIDENT,
  RESOURCE_PARENT_TYPE_PROJECT,
} from '~/contribution_events/constants';

import {
  ISSUE_NOTEABLE_TYPE,
  MERGE_REQUEST_NOTEABLE_TYPE,
  SNIPPET_NOTEABLE_TYPE,
  DESIGN_NOTEABLE_TYPE,
  COMMIT_NOTEABLE_TYPE,
} from '~/notes/constants';

// Private finders
const findEventByAction = (action) => () => events.find((event) => event.action === action);
const findEventByActionAndTargetType = (action, targetType) => () =>
  events.find((event) => event.action === action && event.target?.type === targetType);
const findEventByActionAndIssueType = (action, issueType) => () =>
  events.find((event) => event.action === action && event.target.issue_type === issueType);
const findPushEvent =
  ({
    isNew = false,
    isRemoved = false,
    refType = PUSH_EVENT_REF_TYPE_BRANCH,
    commitCount = 1,
  } = {}) =>
  () =>
    events.find(
      ({ action, ref, commit }) =>
        action === EVENT_TYPE_PUSHED &&
        ref.is_new === isNew &&
        ref.is_removed === isRemoved &&
        ref.type === refType &&
        commit.count === commitCount,
    );
const findEventByActionAndNoteableType = (action, noteableType) => () =>
  events.find((event) => event.action === action && event.noteable?.type === noteableType);
const findCommentedSnippet = (resourceParentType) => () =>
  events.find(
    (event) =>
      event.action === EVENT_TYPE_COMMENTED &&
      event.noteable?.type === SNIPPET_NOTEABLE_TYPE &&
      event.resource_parent?.type === resourceParentType,
  );
const findUpdatedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_UPDATED, targetType);
const findDestroyedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_DESTROYED, targetType);

// Finders that are used by EE
export const findCreatedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_CREATED, targetType);
export const findWorkItemCreatedEvent = (issueType) =>
  findEventByActionAndIssueType(EVENT_TYPE_CREATED, issueType);
export const findClosedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_CREATED, targetType);
export const findWorkItemClosedEvent = (issueType) =>
  findEventByActionAndIssueType(EVENT_TYPE_CLOSED, issueType);
export const findReopenedEvent = (targetType) =>
  findEventByActionAndTargetType(EVENT_TYPE_REOPENED, targetType);
export const findWorkItemReopenedEvent = (issueType) =>
  findEventByActionAndIssueType(EVENT_TYPE_REOPENED, issueType);
export const findCommentedEvent = (noteableType) =>
  findEventByActionAndNoteableType(EVENT_TYPE_COMMENTED, noteableType);

export const eventApproved = findEventByAction(EVENT_TYPE_APPROVED);

export const eventExpired = findEventByAction(EVENT_TYPE_EXPIRED);

export const eventJoined = findEventByAction(EVENT_TYPE_JOINED);

export const eventLeft = findEventByAction(EVENT_TYPE_LEFT);

export const eventMerged = findEventByAction(EVENT_TYPE_MERGED);

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
export const eventProjectCreated = findCreatedEvent(null);
export const eventMilestoneCreated = findCreatedEvent(TARGET_TYPE_MILESTONE);
export const eventIssueCreated = findCreatedEvent(TARGET_TYPE_ISSUE);
export const eventMergeRequestCreated = findCreatedEvent(TARGET_TYPE_MERGE_REQUEST);
export const eventWikiPageCreated = findCreatedEvent(TARGET_TYPE_WIKI);
export const eventDesignCreated = findCreatedEvent(TARGET_TYPE_DESIGN);
export const eventTaskCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_TASK);
export const eventIncidentCreated = findWorkItemCreatedEvent(WORK_ITEM_ISSUE_TYPE_INCIDENT);

export const eventClosed = findEventByAction(EVENT_TYPE_CLOSED);
export const eventMilestoneClosed = findClosedEvent(TARGET_TYPE_MILESTONE);
export const eventIssueClosed = findClosedEvent(TARGET_TYPE_ISSUE);
export const eventMergeRequestClosed = findClosedEvent(TARGET_TYPE_MERGE_REQUEST);
export const eventWikiPageClosed = findClosedEvent(TARGET_TYPE_WIKI);
export const eventDesignClosed = findClosedEvent(TARGET_TYPE_DESIGN);
export const eventTaskClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_TASK);
export const eventIncidentClosed = findWorkItemClosedEvent(WORK_ITEM_ISSUE_TYPE_INCIDENT);

export const eventReopened = findEventByAction(EVENT_TYPE_REOPENED);
export const eventMilestoneReopened = findReopenedEvent(TARGET_TYPE_MILESTONE);
export const eventMergeRequestReopened = findReopenedEvent(TARGET_TYPE_MERGE_REQUEST);
export const eventWikiPageReopened = findReopenedEvent(TARGET_TYPE_WIKI);
export const eventDesignReopened = findReopenedEvent(TARGET_TYPE_DESIGN);
export const eventIssueReopened = findWorkItemReopenedEvent(WORK_ITEM_ISSUE_TYPE_ISSUE);
export const eventTaskReopened = findWorkItemReopenedEvent(WORK_ITEM_ISSUE_TYPE_TASK);
export const eventIncidentReopened = findWorkItemReopenedEvent(WORK_ITEM_ISSUE_TYPE_INCIDENT);

export const eventCommented = findEventByAction(EVENT_TYPE_COMMENTED);
export const eventCommentedIssue = findCommentedEvent(ISSUE_NOTEABLE_TYPE);
export const eventCommentedMergeRequest = findCommentedEvent(MERGE_REQUEST_NOTEABLE_TYPE);
export const eventCommentedSnippet = findCommentedEvent(SNIPPET_NOTEABLE_TYPE);
export const eventCommentedProjectSnippet = findCommentedSnippet(RESOURCE_PARENT_TYPE_PROJECT);
export const eventCommentedPersonalSnippet = findCommentedSnippet(null);
export const eventCommentedDesign = findCommentedEvent(DESIGN_NOTEABLE_TYPE);
// Fixtures do not work for commits because they are not written to the database.
// Manually creating a commented commit event as a workaround.
export const eventCommentedCommit = () => ({
  ...eventCommented(),
  noteable: {
    type: COMMIT_NOTEABLE_TYPE,
    reference_link_text: '83c6aa31',
    web_url: 'http://localhost/group3/project-1/-/commit/83c6aa31482b9076531ed3a880e75627fd6b335c',
    first_line_in_markdown: '\u003cp\u003eMy title 9\u003c/p\u003e',
  },
});

export const eventUpdated = findEventByAction(EVENT_TYPE_UPDATED);
export const eventDesignUpdated = findUpdatedEvent(TARGET_TYPE_DESIGN);
export const eventWikiPageUpdated = findUpdatedEvent(TARGET_TYPE_WIKI);

export const eventDestroyed = findEventByAction(EVENT_TYPE_DESTROYED);
export const eventDesignDestroyed = findDestroyedEvent(TARGET_TYPE_DESIGN);
export const eventWikiPageDestroyed = findDestroyedEvent(TARGET_TYPE_WIKI);
export const eventMilestoneDestroyed = findDestroyedEvent(TARGET_TYPE_MILESTONE);
