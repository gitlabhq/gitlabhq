import createEventHub from '~/helpers/event_hub_factory';

export default createEventHub();

export const EVENT_EDIT_WIKI_START = Symbol('eventEditWikiStart');
export const EVENT_EDIT_WIKI_DONE = Symbol('eventEditWikiDone');
