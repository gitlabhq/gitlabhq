import { SNOWPLOW_JS_SOURCE } from './constants';

export default function getStandardContext({ extra = {} } = {}) {
  const { schema, data = {} } = { ...window.gl?.snowplowStandardContext };

  return {
    schema,
    data: {
      ...data,
      source: SNOWPLOW_JS_SOURCE,
      extra: extra || data.extra,
    },
  };
}
