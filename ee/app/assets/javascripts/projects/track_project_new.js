import Stats from 'ee/stats';

const bindTrackEvents = (container) => {
  Stats.bindTrackableContainer(container);
};

export default bindTrackEvents;
