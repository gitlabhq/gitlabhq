import { SNOWPLOW_JS_SOURCE } from '~/tracking/constants';
import getStandardContext from '~/tracking/get_standard_context';

describe('~/tracking/get_standard_context', () => {
  beforeEach(() => {
    window.gl = window.gl || {};
    window.gl.snowplowStandardContext = {};
  });

  it('returns default object if called without server context', () => {
    expect(getStandardContext()).toStrictEqual({
      schema: undefined,
      data: {
        source: SNOWPLOW_JS_SOURCE,
        extra: {},
      },
    });
  });

  it('returns filled object if called with server context', () => {
    window.gl.snowplowStandardContext = {
      schema: 'iglu:com.gitlab/gitlab_standard',
      data: {
        environment: 'testing',
      },
    };

    expect(getStandardContext()).toStrictEqual({
      schema: 'iglu:com.gitlab/gitlab_standard',
      data: {
        environment: 'testing',
        source: SNOWPLOW_JS_SOURCE,
        extra: {},
      },
    });
  });

  it('always overrides `source` property', () => {
    window.gl.snowplowStandardContext = {
      data: {
        source: 'custom_source',
      },
    };

    expect(getStandardContext().data.source).toBe(SNOWPLOW_JS_SOURCE);
  });

  it('accepts optional `extra` property', () => {
    const extra = { foo: 'bar' };

    expect(getStandardContext({ extra }).data.extra).toBe(extra);
  });
});
