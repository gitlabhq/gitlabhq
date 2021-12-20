import createEventHub from '~/helpers/event_hub_factory';

export default createEventHub();

export const EVENT_OPEN_CONFIRM_MODAL = Symbol('OPEN');
