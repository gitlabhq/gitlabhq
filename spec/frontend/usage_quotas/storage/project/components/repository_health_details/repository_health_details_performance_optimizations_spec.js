import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RepositoryHealthPerformanceOptimizations from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_performance_optimizations.vue';
import { MOCK_REPOSITORY_HEALTH_DETAILS } from 'jest/usage_quotas/storage/mock_data';

describe('RepositoryHealthPerformanceOptimizations', () => {
  let wrapper;

  const defaultProps = {
    healthDetails: MOCK_REPOSITORY_HEALTH_DETAILS,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RepositoryHealthPerformanceOptimizations, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findHeaderText = () => wrapper.findByTestId('performance-header-text');
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findCommitGraphCard = () => wrapper.findByTestId('commit-graph-features');
  const findReachabilityBitmapCard = () => wrapper.findByTestId('reachability-bitmap-features');
  const findMultiPackIndexBitmapCard = () => wrapper.findByTestId('multi-pack-bitmap-features');

  describe('header section', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the header with correct icon and text', () => {
      expect(findGlIcon().props('name')).toBe('dashboard');
      expect(findHeaderText().text()).toContain('Performance optimizations');
    });
  });

  describe('performance cards', () => {
    describe('with all data', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders commit graph card with correct props', () => {
        expect(findCommitGraphCard().props()).toStrictEqual(
          expect.objectContaining({
            headerText: 'Commit graph',
            features: [
              {
                label: 'Bloom filters',
                enabled: MOCK_REPOSITORY_HEALTH_DETAILS.commitGraph.hasBloomFilters,
              },
              {
                label: 'Generation data',
                enabled: MOCK_REPOSITORY_HEALTH_DETAILS.commitGraph.hasGenerationData,
              },
              {
                label: 'Generation data overflow',
                enabled: MOCK_REPOSITORY_HEALTH_DETAILS.commitGraph.hasGenerationDataOverflow,
              },
            ],
            footerText: `Chain length: ${MOCK_REPOSITORY_HEALTH_DETAILS.commitGraph.commitGraphChainLength}`,
            noFeaturesText:
              'No commit graph detected. A commit graph file can significantly speed up Git operations like log, merge-base, and push by pre-computing and caching commit metadata.',
          }),
        );
      });

      it('renders reachability bitmap card with correct props', () => {
        expect(findReachabilityBitmapCard().props()).toStrictEqual(
          expect.objectContaining({
            headerText: 'Reachability bitmap',
            features: [
              { label: 'Hash cache', enabled: MOCK_REPOSITORY_HEALTH_DETAILS.bitmap.hasHashCache },
              {
                label: 'Lookup table',
                enabled: MOCK_REPOSITORY_HEALTH_DETAILS.bitmap.hasLookupTable,
              },
            ],
            noFeaturesText:
              'No reachability bitmap detected. A reachability bitmap can accelerate Git operations that need to determine object reachability, improving performance for clones, fetches, and pushes.',
          }),
        );
      });

      it('renders multi-pack index bitmap card with correct props', () => {
        expect(findMultiPackIndexBitmapCard().props()).toStrictEqual(
          expect.objectContaining({
            headerText: 'Multi-pack index bitmap',
            features: [
              {
                label: 'Hash cache',
                enabled: MOCK_REPOSITORY_HEALTH_DETAILS.multiPackIndexBitmap.hasHashCache,
              },
              {
                label: 'Lookup table',
                enabled: MOCK_REPOSITORY_HEALTH_DETAILS.multiPackIndexBitmap.hasLookupTable,
              },
            ],
            footerText: `Packfile count: ${MOCK_REPOSITORY_HEALTH_DETAILS.multiPackIndex.packfileCount}`,
            noFeaturesText:
              'No multi-pack index bitmap detected. A multi-pack index bitmap can improve object lookup performance across multiple pack files, particularly benefiting fetch and clone operations.',
          }),
        );
      });
    });

    describe('when commit graph data is missing', () => {
      beforeEach(() => {
        createComponent({
          props: { healthDetails: { ...MOCK_REPOSITORY_HEALTH_DETAILS, commitGraph: null } },
        });
      });

      it('renders commit graph card with correct props', () => {
        expect(findCommitGraphCard().props()).toStrictEqual(
          expect.objectContaining({
            headerText: 'Commit graph',
            features: [],
            footerText: null,
            noFeaturesText:
              'No commit graph detected. A commit graph file can significantly speed up Git operations like log, merge-base, and push by pre-computing and caching commit metadata.',
          }),
        );
      });
    });

    describe('when readability bitmap data is missing', () => {
      beforeEach(() => {
        createComponent({
          props: { healthDetails: { ...MOCK_REPOSITORY_HEALTH_DETAILS, bitmap: null } },
        });
      });

      it('renders reachability bitmap card with correct props', () => {
        expect(findReachabilityBitmapCard().props()).toStrictEqual(
          expect.objectContaining({
            headerText: 'Reachability bitmap',
            features: [],
            noFeaturesText:
              'No reachability bitmap detected. A reachability bitmap can accelerate Git operations that need to determine object reachability, improving performance for clones, fetches, and pushes.',
          }),
        );
      });
    });

    describe('when multi-pack bitmap data is missing', () => {
      beforeEach(() => {
        createComponent({
          props: {
            healthDetails: {
              ...MOCK_REPOSITORY_HEALTH_DETAILS,
              multiPackIndexBitmap: null,
              multiPackIndex: null,
            },
          },
        });
      });

      it('renders multi-pack index bitmap card with correct props', () => {
        expect(findMultiPackIndexBitmapCard().props()).toStrictEqual(
          expect.objectContaining({
            headerText: 'Multi-pack index bitmap',
            features: [],
            footerText: null,
            noFeaturesText:
              'No multi-pack index bitmap detected. A multi-pack index bitmap can improve object lookup performance across multiple pack files, particularly benefiting fetch and clone operations.',
          }),
        );
      });
    });
  });
});
