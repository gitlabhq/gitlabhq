import { SNOWPLOW_JS_SOURCE, GOOGLE_ANALYTICS_ID_COOKIE_NAME } from '~/tracking/constants';
import getStandardContext from '~/tracking/get_standard_context';
import { setCookie, removeCookie } from '~/lib/utils/common_utils';

const TEST_GA_ID = 'GA1.2.345678901.234567891';
const TEST_BASE_DATA = {
  source: SNOWPLOW_JS_SOURCE,
  google_analytics_id: '',
  extra: {},
};

describe('~/tracking/get_standard_context', () => {
  beforeEach(() => {
    window.gl = window.gl || {};
    window.gl.snowplowStandardContext = {};
  });

  it('returns default object if called without server context', () => {
    expect(getStandardContext()).toStrictEqual({
      schema: undefined,
      data: TEST_BASE_DATA,
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
        ...TEST_BASE_DATA,
        environment: 'testing',
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

    expect(getStandardContext({ extra }).data.extra).toStrictEqual(extra);
  });

  describe('with Google Analytics cookie present', () => {
    afterEach(() => {
      removeCookie(GOOGLE_ANALYTICS_ID_COOKIE_NAME);
    });

    it('appends Google Analytics ID', () => {
      setCookie(GOOGLE_ANALYTICS_ID_COOKIE_NAME, TEST_GA_ID);
      expect(getStandardContext().data.google_analytics_id).toBe(TEST_GA_ID);
    });
  });
});
