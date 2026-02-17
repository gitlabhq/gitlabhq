import { GlButton, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { formatDate } from '~/lib/utils/datetime_utility';
import RepositoryHealthDetailsHeader from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_header.vue';
import { MOCK_REPOSITORY_HEALTH_DETAILS } from 'jest/usage_quotas/storage/mock_data';

const MOCK_FORMATTED_DATE = '2026-01-01';

jest.mock('~/lib/utils/datetime_utility', () => ({
  formatDate: jest.fn(() => MOCK_FORMATTED_DATE),
}));

describe('RepositoryHealthDetailsHeader', () => {
  let wrapper;

  const defaultProps = {
    healthDetails: MOCK_REPOSITORY_HEALTH_DETAILS,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RepositoryHealthDetailsHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('repository-health-header-title');
  const findRegenerateButton = () => wrapper.findComponent(GlButton);
  const findLastUpdateDate = () => wrapper.findByTestId('repository-health-header-last-updated');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the header title', () => {
      expect(findTitle().text()).toBe('Repository health');
    });

    it('renders the regenerate report button', () => {
      expect(findRegenerateButton().text()).toBe('Regenerate report');
    });

    it('renders the last update text with formatted date', () => {
      expect(formatDate).toHaveBeenCalledWith(MOCK_REPOSITORY_HEALTH_DETAILS.updatedAt);
      expect(findLastUpdateDate().text().replace(/\s+/g, ' ')).toBe(
        `Last update: ${MOCK_FORMATTED_DATE}`,
      );
    });
  });

  describe('when data is missing', () => {
    beforeEach(() => {
      createComponent({
        healthDetails: {
          ...MOCK_REPOSITORY_HEALTH_DETAILS,
          updatedAt: null,
        },
      });
    });

    it('renders Last update: Unknown', () => {
      expect(formatDate).not.toHaveBeenCalled();
      expect(findLastUpdateDate().text().replace(/\s+/g, ' ')).toBe('Last update: Unknown');
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits regenerate-report event when button is clicked', async () => {
      findRegenerateButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('regenerate-report')).toHaveLength(1);
    });
  });
});
