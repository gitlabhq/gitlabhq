import Api from '~/api';
import Tracking from '~/tracking';

// Snowplow tracking constants
const DESIGN_TRACKING_CONTEXT_SCHEMAS = {
  VIEW_DESIGN_SCHEMA: 'iglu:com.gitlab/design_management_context/jsonschema/1-0-0',
};

export const DESIGN_TRACKING_PAGE_NAME = 'projects:issues:design';

export const DESIGN_SNOWPLOW_EVENT_TYPES = {
  VIEW_DESIGN: 'view_design',
  CREATE_DESIGN: 'create_design',
  UPDATE_DESIGN: 'update_design',
};

export const DESIGN_SERVICE_PING_EVENT_TYPES = {
  DESIGN_ACTION: 'design_action',
};

/**
 * Track "design detail" view in Snowplow
 */
// eslint-disable-next-line max-params
export function trackDesignDetailView(
  referer = '',
  owner = '',
  designVersion = 1,
  latestVersion = false,
) {
  const eventName = DESIGN_SNOWPLOW_EVENT_TYPES.VIEW_DESIGN;

  Tracking.event(DESIGN_TRACKING_PAGE_NAME, eventName, {
    label: eventName,
    context: {
      schema: DESIGN_TRACKING_CONTEXT_SCHEMAS.VIEW_DESIGN_SCHEMA,
      data: {
        'design-version-number': designVersion,
        'design-is-current-version': latestVersion,
        'internal-object-referrer': referer,
        'design-collection-owner': owner,
      },
    },
  });
}

export function trackDesignCreate() {
  return Tracking.event(DESIGN_TRACKING_PAGE_NAME, DESIGN_SNOWPLOW_EVENT_TYPES.CREATE_DESIGN);
}

export function trackDesignUpdate() {
  return Tracking.event(DESIGN_TRACKING_PAGE_NAME, DESIGN_SNOWPLOW_EVENT_TYPES.UPDATE_DESIGN);
}

/**
 * Track "design detail" view via service ping
 */
export function servicePingDesignDetailView() {
  Api.trackRedisHllUserEvent(DESIGN_SERVICE_PING_EVENT_TYPES.DESIGN_ACTION);
}
