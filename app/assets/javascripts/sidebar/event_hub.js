import createEventHub from '~/helpers/event_hub_factory';

const eventHub = createEventHub();

// TODO: remove eventHub hack after code splitting refactor
window.emitSidebarEvent = (...args) => eventHub.$emit(...args);

export default eventHub;
