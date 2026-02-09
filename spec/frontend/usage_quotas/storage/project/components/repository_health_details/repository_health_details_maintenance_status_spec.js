import { GlIcon } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RepositoryHealthMaintenanceStatus from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_maintenance_status.vue';
import { MOCK_REPOSITORY_HEALTH_DETAILS } from 'jest/usage_quotas/storage/mock_data';

const MOCK_FORMATTED_DATE = 'January 1, 2022 at 12:00:00 AM UTC';
const MOCK_FORMATTED_TIME_AGO = '2 years ago';

jest.mock('~/lib/utils/datetime_utility', () => ({
  formatDate: jest.fn(() => MOCK_FORMATTED_DATE),
  getTimeago: jest.fn(() => ({ format: jest.fn(() => MOCK_FORMATTED_TIME_AGO) })),
}));

describe('RepositoryHealthMaintenanceStatus', () => {
  let wrapper;

  const defaultProps = {
    healthDetails: MOCK_REPOSITORY_HEALTH_DETAILS,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RepositoryHealthMaintenanceStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findHeaderText = () => wrapper.findByTestId('maintenance-status-header');
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findLastRepackTimeAgoStat = () => wrapper.findComponent(GlSingleStat);
  const findLastRepackDateString = () => wrapper.findByTestId('last-full-repack-date-string');
  const findObjectPackingStats = () => wrapper.findAllByTestId('object-packing-stat');

  describe('header section', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the header with correct icon and text', () => {
      expect(findGlIcon().props('name')).toBe('work');
      expect(findHeaderText().text()).toContain('Maintenance status');
    });
  });

  describe('last full repack card', () => {
    describe('with lastFullRepack data', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders GlSingleStat with timeago value', () => {
        expect(findLastRepackTimeAgoStat().props()).toStrictEqual(
          expect.objectContaining({
            value: MOCK_FORMATTED_TIME_AGO,
            title: 'Last full repack',
            shouldAnimate: false,
          }),
        );
      });

      it('renders formatted date string', () => {
        expect(findLastRepackDateString().text()).toBe(MOCK_FORMATTED_DATE);
      });
    });

    describe('without lastFullRepack data', () => {
      beforeEach(() => {
        createComponent({
          props: { healthDetails: { ...MOCK_REPOSITORY_HEALTH_DETAILS, lastFullRepack: null } },
        });
      });

      it('renders GlSingleStat with unknown value', () => {
        expect(findLastRepackTimeAgoStat().props()).toStrictEqual(
          expect.objectContaining({
            value: 'Unknown',
            title: 'Last full repack',
            shouldAnimate: false,
          }),
        );
      });

      it('does not render formatted date string', () => {
        expect(findLastRepackDateString().exists()).toBe(false);
      });
    });
  });

  describe('object packing card', () => {
    describe('with data', () => {
      beforeEach(() => {
        createComponent();
      });

      it.each`
        index | expectedLabel      | expectedValue
        ${0}  | ${'Packfiles'}     | ${MOCK_REPOSITORY_HEALTH_DETAILS.objects.packfileCount}
        ${1}  | ${'Cruft packs'}   | ${MOCK_REPOSITORY_HEALTH_DETAILS.objects.cruftCount}
        ${2}  | ${'Loose objects'} | ${MOCK_REPOSITORY_HEALTH_DETAILS.objects.looseObjectsCount}
      `('renders $expectedLabel stat correctly', ({ index, expectedLabel, expectedValue }) => {
        expect(findObjectPackingStats().at(index).text()).toBe(`${expectedValue} ${expectedLabel}`);
      });
    });

    describe('with no data', () => {
      beforeEach(() => {
        createComponent({
          props: { healthDetails: { ...MOCK_REPOSITORY_HEALTH_DETAILS, objects: null } },
        });
      });

      it.each`
        index | expectedLabel      | expectedValue
        ${0}  | ${'Packfiles'}     | ${0}
        ${1}  | ${'Cruft packs'}   | ${0}
        ${2}  | ${'Loose objects'} | ${0}
      `('renders $expectedLabel stat correctly', ({ index, expectedLabel, expectedValue }) => {
        expect(findObjectPackingStats().at(index).text()).toBe(`${expectedValue} ${expectedLabel}`);
      });
    });
  });
});
