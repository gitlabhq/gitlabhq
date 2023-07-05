import events from 'test_fixtures/controller/users/activity.json';
import {
  EVENT_TYPE_APPROVED,
  EVENT_TYPE_EXPIRED,
  EVENT_TYPE_JOINED,
  EVENT_TYPE_LEFT,
  EVENT_TYPE_PUSHED,
  PUSH_EVENT_REF_TYPE_BRANCH,
  PUSH_EVENT_REF_TYPE_TAG,
} from '~/contribution_events/constants';

const findEventByAction = (action) => events.find((event) => event.action === action);

export const eventApproved = () => findEventByAction(EVENT_TYPE_APPROVED);

export const eventExpired = () => findEventByAction(EVENT_TYPE_EXPIRED);

export const eventJoined = () => findEventByAction(EVENT_TYPE_JOINED);

export const eventLeft = () => findEventByAction(EVENT_TYPE_LEFT);

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
