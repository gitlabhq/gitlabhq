import { GlIcon, GlCard, GlSprintf, GlProgressBar } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RepositoryHealthDetailsStorageBreakdown from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_storage_breakdown.vue';
import { MOCK_REPOSITORY_HEALTH_DETAILS } from 'jest/usage_quotas/storage/mock_data';

jest.mock('~/lib/utils/number_utils', () => ({
  numberToHumanSize: jest.fn((size) => `${size} MiB`),
}));

describe('RepositoryHealthDetailsStorageBreakdown', () => {
  let wrapper;

  const defaultProps = {
    healthDetails: MOCK_REPOSITORY_HEALTH_DETAILS,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RepositoryHealthDetailsStorageBreakdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('repository-health-storage-title');
  const findDiskIcon = () => wrapper.findComponent(GlIcon);
  const findGlCards = () => wrapper.findAllComponents(GlCard);
  const findGlSingleStats = () => wrapper.findAllComponents(GlSingleStat);
  const findProgressBars = () => wrapper.findAllComponents(GlProgressBar);

  const findObjectsStorageCard = () =>
    wrapper.findByTestId('repository-health-storage-object-storage-card');
  const findObjectsStorageCardStats = () => findObjectsStorageCard().findComponent(GlSingleStat);
  const findReferencesCard = () =>
    wrapper.findByTestId('repository-health-storage-references-card');
  const findReferencesCardStats = () => findReferencesCard().findComponent(GlSingleStat);

  const findRecentObjects = () => wrapper.findByTestId('repository-health-storage-recent-objects');
  const findRecentObjectsPercentage = () =>
    wrapper.findByTestId('repository-health-storage-recent-objects-percentage');
  const findRecentObjectsProgressBar = () => findRecentObjects().findComponent(GlProgressBar);

  const findStaleObjects = () => wrapper.findByTestId('repository-health-storage-stale-objects');
  const findStaleObjectsPercentage = () =>
    wrapper.findByTestId('repository-health-storage-stale-objects-percentage');
  const findStaleObjectsProgressBar = () => findStaleObjects().findComponent(GlProgressBar);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the storage breakdown title with disk icon', () => {
      expect(findTitle().text()).toContain('Storage breakdown');
      expect(findDiskIcon().props('name')).toBe('disk');
    });

    it('renders three cards', () => {
      expect(findGlCards()).toHaveLength(3);
    });

    it('renders two single stat components for objects and references', () => {
      expect(findGlSingleStats()).toHaveLength(2);
    });

    it('renders two progress bars for recent and stale objects', () => {
      expect(findProgressBars()).toHaveLength(2);
    });
  });

  describe('objects storage card', () => {
    describe.each`
      objectSize | totalSize | expectedStatText | expectedPercentageText
      ${null}    | ${null}   | ${'Unknown'}     | ${'Unknown of total'}
      ${null}    | ${0}      | ${'Unknown'}     | ${'Unknown of total'}
      ${null}    | ${200}    | ${'Unknown'}     | ${'Unknown of total'}
      ${0}       | ${null}   | ${'0 MiB'}       | ${'Unknown of total'}
      ${0}       | ${0}      | ${'0 MiB'}       | ${'Unknown of total'}
      ${0}       | ${200}    | ${'0 MiB'}       | ${'0.00% of total'}
      ${100}     | ${null}   | ${'100 MiB'}     | ${'Unknown of total'}
      ${100}     | ${0}      | ${'100 MiB'}     | ${'Unknown of total'}
      ${100}     | ${200}    | ${'100 MiB'}     | ${'50.00% of total'}
    `(
      'when object.size is $objectSize and healthDetails.size is $totalSize',
      ({ objectSize, totalSize, expectedStatText, expectedPercentageText }) => {
        beforeEach(() => {
          createComponent({
            healthDetails: {
              ...MOCK_REPOSITORY_HEALTH_DETAILS,
              size: totalSize,
              objects: {
                size: objectSize,
              },
            },
          });
        });

        it('displays objects storage size stat correctly', () => {
          expect(findObjectsStorageCardStats().props('title')).toBe('Objects storage');
          expect(findObjectsStorageCardStats().props('value')).toBe(expectedStatText);
        });

        it('displays object storage size as a percentage of total', () => {
          expect(findObjectsStorageCard().text().replace(/\s+/g, ' ')).toContain(
            expectedPercentageText,
          );
        });
      },
    );
  });

  describe('references card', () => {
    describe.each`
      packedSize | looseCount | expectedStatText | expectedRefsText
      ${null}    | ${null}    | ${'Unknown'}     | ${'0 loose refs'}
      ${null}    | ${0}       | ${'Unknown'}     | ${'0 loose refs'}
      ${null}    | ${10}      | ${'Unknown'}     | ${'0 loose refs'}
      ${0}       | ${null}    | ${'0 MiB'}       | ${'0 loose refs'}
      ${0}       | ${0}       | ${'0 MiB'}       | ${'0 loose refs'}
      ${0}       | ${10}      | ${'0 MiB'}       | ${'0 loose refs'}
      ${100}     | ${null}    | ${'100 MiB'}     | ${'0 loose refs'}
      ${100}     | ${0}       | ${'100 MiB'}     | ${'0 loose refs'}
      ${100}     | ${10}      | ${'100 MiB'}     | ${'0 loose refs'}
    `(
      'when references.packedSize is $packedSize and references.looseCount is $looseCount',
      ({ packedSize, looseCount, expectedStatText, expectedRefsText }) => {
        beforeEach(() => {
          createComponent({
            healthDetails: {
              ...MOCK_REPOSITORY_HEALTH_DETAILS,
              references: {
                packedSize,
                looseCount,
              },
            },
          });
        });

        it('displays reference packed size stat correctly', () => {
          expect(findReferencesCardStats().props('title')).toBe('References');
          expect(findReferencesCardStats().props('value')).toBe(expectedStatText);
        });

        it('displays total loose refs', () => {
          expect(findReferencesCard().text().replace(/\s+/g, ' ')).toContain(expectedRefsText);
        });
      },
    );
  });

  describe('recent objects progress bar', () => {
    describe.each`
      recentSize | objectSize | expectedPercentText | expectedPercentValue
      ${null}    | ${null}    | ${'Unknown'}        | ${'Unknown'}
      ${null}    | ${0}       | ${'Unknown'}        | ${'Unknown'}
      ${null}    | ${200}     | ${'Unknown'}        | ${'Unknown'}
      ${0}       | ${null}    | ${'0 MiB'}          | ${'Unknown'}
      ${0}       | ${0}       | ${'0 MiB'}          | ${'Unknown'}
      ${0}       | ${200}     | ${'0 MiB'}          | ${'0.00%'}
      ${100}     | ${null}    | ${'100 MiB'}        | ${'Unknown'}
      ${100}     | ${0}       | ${'100 MiB'}        | ${'Unknown'}
      ${100}     | ${200}     | ${'100 MiB'}        | ${'50.00%'}
    `(
      'when objects.recentSize is $recentSize and objects.size is $objectSize',
      ({ recentSize, objectSize, expectedPercentText, expectedPercentValue }) => {
        beforeEach(() => {
          createComponent({
            healthDetails: {
              ...MOCK_REPOSITORY_HEALTH_DETAILS,
              objects: {
                recentSize,
                size: objectSize,
              },
            },
          });
        });

        it('displays correct progress bar percentage text', () => {
          expect(findRecentObjects().text()).toContain('Recent objects');
          expect(findRecentObjectsPercentage().classes('gl-text-green-600')).toBe(true);
          expect(findRecentObjectsPercentage().text()).toBe(
            `${expectedPercentText} (${expectedPercentValue})`,
          );
        });

        it('displays the progress bar correctly', () => {
          expect(findRecentObjectsProgressBar().props('variant')).toBe('success');
          expect(findRecentObjectsProgressBar().props('value')).toBe(expectedPercentValue);
        });
      },
    );
  });

  describe('stale objects progress bar', () => {
    describe.each`
      staleSize | objectSize | expectedPercentText | expectedPercentValue
      ${null}   | ${null}    | ${'Unknown'}        | ${'Unknown'}
      ${null}   | ${0}       | ${'Unknown'}        | ${'Unknown'}
      ${null}   | ${200}     | ${'Unknown'}        | ${'Unknown'}
      ${0}      | ${null}    | ${'0 MiB'}          | ${'Unknown'}
      ${0}      | ${0}       | ${'0 MiB'}          | ${'Unknown'}
      ${0}      | ${200}     | ${'0 MiB'}          | ${'0.00%'}
      ${100}    | ${null}    | ${'100 MiB'}        | ${'Unknown'}
      ${100}    | ${0}       | ${'100 MiB'}        | ${'Unknown'}
      ${100}    | ${200}     | ${'100 MiB'}        | ${'50.00%'}
    `(
      'when objects.staleSize is $staleSize and objects.size is $objectSize',
      ({ staleSize, objectSize, expectedPercentText, expectedPercentValue }) => {
        beforeEach(() => {
          createComponent({
            healthDetails: {
              ...MOCK_REPOSITORY_HEALTH_DETAILS,
              objects: {
                staleSize,
                size: objectSize,
              },
            },
          });
        });

        it('displays correct progress bar percentage text', () => {
          expect(findStaleObjects().text()).toContain('Stale objects');
          expect(findStaleObjectsPercentage().classes('gl-text-green-600')).not.toBe(true);
          expect(findStaleObjectsPercentage().text()).toBe(
            `${expectedPercentText} (${expectedPercentValue})`,
          );
        });

        it('displays the progress bar correctly', () => {
          expect(findStaleObjectsProgressBar().props('variant')).toBe('warning');
          expect(findStaleObjectsProgressBar().props('value')).toBe(expectedPercentValue);
        });
      },
    );
  });
});
