import { getCookie } from '~/lib/utils/common_utils';
import { SNOWPLOW_JS_SOURCE, GOOGLE_ANALYTICS_ID_COOKIE_NAME } from './constants';

export default function getStandardContext({ extra = {} } = {}) {
  const { schema, data = {} } = { ...window.gl?.snowplowStandardContext };

  return {
    schema,
    data: {
      ...data,
      source: SNOWPLOW_JS_SOURCE,
      google_analytics_id: getCookie(GOOGLE_ANALYTICS_ID_COOKIE_NAME) ?? '',
      extra: { ...data.extra, ...extra },
    },
  };
}
