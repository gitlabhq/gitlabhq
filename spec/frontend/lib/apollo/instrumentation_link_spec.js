import { testApolloLink } from 'helpers/test_apollo_link';
import { getInstrumentationLink, FEATURE_CATEGORY_HEADER } from '~/lib/apollo/instrumentation_link';

const TEST_FEATURE_CATEGORY = 'foo_feature';

describe('~/lib/apollo/instrumentation_link', () => {
  const setFeatureCategory = (val) => {
    window.gon.feature_category = val;
  };

  afterEach(() => {
    getInstrumentationLink.cache.clear();
  });

  describe('getInstrumentationLink', () => {
    describe('with no gon.feature_category', () => {
      beforeEach(() => {
        setFeatureCategory(null);
      });

      it('returns null', () => {
        expect(getInstrumentationLink()).toBe(null);
      });
    });

    describe('with gon.feature_category', () => {
      beforeEach(() => {
        setFeatureCategory(TEST_FEATURE_CATEGORY);
      });

      it('returns memoized apollo link', () => {
        const result = getInstrumentationLink();

        // expect.any(ApolloLink) doesn't work for some reason...
        expect(result).toHaveProp('request');
        expect(result).toBe(getInstrumentationLink());
      });

      it('adds a feature category header from the returned apollo link', async () => {
        const defaultHeaders = { Authorization: 'foo' };
        const operation = await testApolloLink(getInstrumentationLink(), {
          context: { headers: defaultHeaders },
        });

        const { headers } = operation.getContext();

        expect(headers).toEqual({
          ...defaultHeaders,
          [FEATURE_CATEGORY_HEADER]: TEST_FEATURE_CATEGORY,
        });
      });
    });
  });
});
