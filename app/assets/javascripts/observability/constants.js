import { __ } from '~/locale';

export const MESSAGE_EVENT_TYPE = Object.freeze({
  GOUI_LOADED: 'GOUI_LOADED',
  GOUI_ROUTE_UPDATE: 'GOUI_ROUTE_UPDATE',
});

export const OBSERVABILITY_ROUTES = Object.freeze({
  DASHBOARDS: 'observability/dashboards',
  EXPLORE: 'observability/explore',
  MANAGE: 'observability/manage',
});

export const SKELETON_VARIANTS_BY_ROUTE = Object.freeze({
  [OBSERVABILITY_ROUTES.DASHBOARDS]: 'dashboards',
  [OBSERVABILITY_ROUTES.EXPLORE]: 'explore',
  [OBSERVABILITY_ROUTES.MANAGE]: 'manage',
});

export const SKELETON_VARIANT_EMBED = 'embed';

export const SKELETON_STATE = Object.freeze({
  ERROR: 'error',
  VISIBLE: 'visible',
  HIDDEN: 'hidden',
});

export const DEFAULT_TIMERS = Object.freeze({
  TIMEOUT_MS: 20000,
  CONTENT_WAIT_MS: 500,
});

export const TIMEOUT_ERROR_LABEL = __('Unable to load the page');
export const TIMEOUT_ERROR_MESSAGE = __('Reload the page to try again.');

export const INLINE_EMBED_DIMENSIONS = Object.freeze({
  HEIGHT: '366px',
  WIDTH: '768px',
});

export const FULL_APP_DIMENSIONS = Object.freeze({
  HEIGHT: '100%',
  WIDTH: '100%',
});
