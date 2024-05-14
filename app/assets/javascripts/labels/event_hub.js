import createEventHub from '~/helpers/event_hub_factory';

export default createEventHub();

export const EVENT_OPEN_DELETE_LABEL_MODAL = Symbol('deleteLabelModal:open');
export const EVENT_DELETE_LABEL_MODAL_SUCCESS = Symbol('deleteLabelModal:success');
export const EVENT_OPEN_PROMOTE_LABEL_MODAL = Symbol('promoteLabelModal:open');
