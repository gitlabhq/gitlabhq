import createEventHub from '~/helpers/event_hub_factory';

const eventHubs = {};

export const eventHubByKey = (key) => {
  eventHubs[key] = eventHubs[key] || createEventHub();
  return eventHubs[key];
};
