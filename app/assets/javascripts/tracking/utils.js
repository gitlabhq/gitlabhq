import { omitBy, isUndefined } from 'lodash';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData } from '~/experimentation/utils';
import {
  ACTION_ATTR_SELECTOR,
  LOAD_ACTION_ATTR_SELECTOR,
  URLS_CACHE_STORAGE_KEY,
  REFERRER_TTL,
  INTERNAL_EVENTS_SELECTOR,
  BASE_ADDITIONAL_PROPERTIES,
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
    trackValue,
    trackExtra,
    trackExperiment,
    trackContext,
    trackLabel,
    trackProperty,
  } = el?.dataset || {};

  const action = `${trackAction}${suffix || ''}`;
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

export const createInternalEventPayload = (el) => {
  const {
    eventTracking,
    eventLabel,
    eventProperty,
    eventValue,
    eventAdditional = '{}',
  } = el?.dataset || {};

  let parsedEventAdditional = {};

  try {
    parsedEventAdditional = JSON.parse(eventAdditional);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to parse eventAdditional attribute:', eventAdditional);
  }

  return {
    event: eventTracking,
    additionalProperties: omitBy(
      {
        label: eventLabel,
        property: eventProperty,
        value: parseInt(eventValue, 10) || undefined,
        ...parsedEventAdditional,
      },
      isUndefined,
    ),
  };
};

export const InternalEventHandler = (e, func) => {
  const el = e.target.closest(INTERNAL_EVENTS_SELECTOR);

  if (!el) {
    return;
  }
  const { event, additionalProperties = {} } = createInternalEventPayload(el);

  func(event, additionalProperties);
};

export const eventHandler = (e, func, opts = {}) => {
  const actionSelector = `${ACTION_ATTR_SELECTOR}:not(${LOAD_ACTION_ATTR_SELECTOR})`;
  const el = e.target.closest(actionSelector);

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

export const filterOldReferrersCacheEntries = (cache) => {
  const now = Date.now();

  return cache.filter((entry) => entry.timestamp && entry.timestamp > now - REFERRER_TTL);
};

export const getReferrersCache = () => {
  try {
    const referrers = JSON.parse(window.localStorage.getItem(URLS_CACHE_STORAGE_KEY) || '[]');

    return filterOldReferrersCacheEntries(referrers);
  } catch {
    return [];
  }
};

export const addReferrersCacheEntry = (cache, entry) => {
  const referrers = JSON.stringify([{ ...entry, timestamp: Date.now() }, ...cache]);

  window.localStorage.setItem(URLS_CACHE_STORAGE_KEY, referrers);
};

function validateProperty(obj, key, allowedTypes) {
  if (!obj[key]) return;
  if (obj[key] === null) return;

  const isValidType = allowedTypes.includes(typeof obj[key]);

  if (!isValidType) {
    throw new Error(
      `${key} should be of type: ${allowedTypes.join(', ')}. Provided type is: ${typeof obj[key]}.`,
    );
  }
}

export const validateAdditionalProperties = (additionalProperties) => {
  const baseKeys = Object.keys(BASE_ADDITIONAL_PROPERTIES);

  baseKeys.forEach((key) => {
    if (additionalProperties[key]) {
      validateProperty(additionalProperties, key, BASE_ADDITIONAL_PROPERTIES[key]);
    }
  });
};

function filterProperties(additionalProperties, predicate) {
  return Object.keys(additionalProperties).reduce((acc, key) => {
    if (predicate(key)) {
      return { ...acc, [key]: additionalProperties[key] };
    }
    return acc;
  }, {});
}

export function getCustomAdditionalProperties(additionalProperties) {
  return filterProperties(
    additionalProperties,
    (key) => !Object.keys(BASE_ADDITIONAL_PROPERTIES).includes(key),
  );
}

export function getBaseAdditionalProperties(additionalProperties) {
  return filterProperties(additionalProperties, (key) =>
    Object.keys(BASE_ADDITIONAL_PROPERTIES).includes(key),
  );
}
