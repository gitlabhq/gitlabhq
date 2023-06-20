import {
  EVENT_TYPE_APPROVED,
  EVENT_TYPE_EXPIRED,
  EVENT_TYPE_JOINED,
  EVENT_TYPE_LEFT,
} from '~/contribution_events/constants';

export const eventApproved = (events) =>
  events.find((event) => event.action === EVENT_TYPE_APPROVED);

export const eventExpired = (events) => events.find((event) => event.action === EVENT_TYPE_EXPIRED);

export const eventJoined = (events) => events.find((event) => event.action === EVENT_TYPE_JOINED);

export const eventLeft = (events) => events.find((event) => event.action === EVENT_TYPE_LEFT);
