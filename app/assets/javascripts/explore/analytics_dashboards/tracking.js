import { v4 as uuidv4 } from 'uuid';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { Tracker } from '~/tracking/tracker';
import { isEventEligible, validateAdditionalProperties } from '~/tracking/utils';

export const EVENT_VIEW_DASHBOARD = 'view_explore_analytics_dashboard';

const TRACK_EVENTS_PATH = '/api/:version/usage_data/track_events';

export const scopeTypeOf = (namespaces) => {
  const projects = namespaces.filter(({ type }) => type === TYPENAME_PROJECT).length;

  if (projects && projects < namespaces.length) return 'mixed';

  return projects ? 'project' : 'group';
};

// Explore pages have no group or project of their own, so the page context that frontend events
// normally borrow their namespace from is empty. The batch endpoint takes one per event instead,
// and sends the Snowplow event from the backend with that namespace attached.
//
// One event per selected namespace, so every customer in a multi-select scope is counted. They
// share a `view_id`, so analysis can still count the view itself once.
export const trackDashboardEvent = (event, namespaces, additionalProperties = {}) => {
  if (!gon.current_user_id || !namespaces.length || !isEventEligible(event)) return null;

  const properties = {
    ...additionalProperties,
    view_id: uuidv4(),
    scope_count: namespaces.length,
    scope_type: scopeTypeOf(namespaces),
  };
  validateAdditionalProperties(properties);

  const events = namespaces.map(({ id, type }) => ({
    event,
    [type === TYPENAME_PROJECT ? 'project_id' : 'namespace_id']: getIdFromGraphQLId(id),
    additional_properties: properties,
    // Honors the same opt-outs (Global Privacy Control, disabled Snowplow) as events sent from
    // the browser.
    send_to_snowplow: Tracker.enabled(),
  }));

  return axios
    .post(Api.buildUrl(TRACK_EVENTS_PATH), { events })
    .catch((error) => Sentry.captureException(error));
};
