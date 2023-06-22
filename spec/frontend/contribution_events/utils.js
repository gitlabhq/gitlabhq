import events from 'test_fixtures/controller/users/activity.json';
import {
  EVENT_TYPE_APPROVED,
  EVENT_TYPE_EXPIRED,
  EVENT_TYPE_JOINED,
  EVENT_TYPE_LEFT,
} from '~/contribution_events/constants';

const findEventByAction = (action) => events.find((event) => event.action === action);

export const eventApproved = () => findEventByAction(EVENT_TYPE_APPROVED);

export const eventExpired = () => findEventByAction(EVENT_TYPE_EXPIRED);

export const eventJoined = () => findEventByAction(EVENT_TYPE_JOINED);

export const eventLeft = () => findEventByAction(EVENT_TYPE_LEFT);
