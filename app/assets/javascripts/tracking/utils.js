import { omitBy, isUndefined } from 'lodash';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData } from '~/experimentation/utils';
import {
  ACTION_ATTR_SELECTOR,
  LOAD_ACTION_ATTR_SELECTOR,
  DEPRECATED_EVENT_ATTR_SELECTOR,
  DEPRECATED_LOAD_EVENT_ATTR_SELECTOR,
} from './constants';

export const addExperimentContext = (opts) => {
  const { experiment, ...options } = opts;

  if (experiment) {
    const data = getExperimentData(experiment);
    if (data) {
      const context = { schema: TRACKING_CONTEXT_SCHEMA, data };
      return { ...options, context };
    }
  }

  return options;
};

export const createEventPayload = (el, { suffix = '' } = {}) => {
  const {
    trackAction,
    trackEvent,
    trackValue,
    trackExtra,
    trackExperiment,
    trackContext,
    trackLabel,
    trackProperty,
  } = el?.dataset || {};

  const action = (trackAction || trackEvent) + (suffix || '');
  let value = trackValue || el.value || undefined;

  if (el.type === 'checkbox' && !el.checked) {
    value = 0;
  }

  let extra = trackExtra;

  if (extra !== undefined) {
    try {
      extra = JSON.parse(extra);
    } catch (e) {
      extra = undefined;
    }
  }

  const context = addExperimentContext({
    experiment: trackExperiment,
    context: trackContext,
  });

  const data = {
    label: trackLabel,
    property: trackProperty,
    value,
    extra,
    ...context,
  };

  return {
    action,
    data: omitBy(data, isUndefined),
  };
};

export const eventHandler = (e, func, opts = {}) => {
  const actionSelector = `${ACTION_ATTR_SELECTOR}:not(${LOAD_ACTION_ATTR_SELECTOR})`;
  const deprecatedEventSelector = `${DEPRECATED_EVENT_ATTR_SELECTOR}:not(${DEPRECATED_LOAD_EVENT_ATTR_SELECTOR})`;
  const el = e.target.closest(`${actionSelector}, ${deprecatedEventSelector}`);

  if (!el) {
    return;
  }

  const { action, data } = createEventPayload(el, opts);
  func(opts.category, action, data);
};

export const getEventHandlers = (category, func) => {
  const handler = (opts) => (e) => eventHandler(e, func, { ...{ category }, ...opts });
  const handlers = [];

  handlers.push({ name: 'click', func: handler() });
  handlers.push({ name: 'show.bs.dropdown', func: handler({ suffix: '_show' }) });
  handlers.push({ name: 'hide.bs.dropdown', func: handler({ suffix: '_hide' }) });

  return handlers;
};

export const renameKey = (o, oldKey, newKey) => {
  const ret = {};
  delete Object.assign(ret, o, { [newKey]: o[oldKey] })[oldKey];

  return ret;
};
