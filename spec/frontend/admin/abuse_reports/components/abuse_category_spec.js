import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseCategory from '~/admin/abuse_reports/components/abuse_category.vue';
import { ABUSE_CATEGORIES } from '~/admin/abuse_reports/constants';
import { mockAbuseReports } from '../mock_data';

describe('AbuseCategory', () => {
  let wrapper;

  const mockAbuseReport = mockAbuseReports[0];
  const category = ABUSE_CATEGORIES[mockAbuseReport.category];

  const findLabel = () => wrapper.findComponent(GlLabel);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(AbuseCategory, {
      propsData: {
        category: mockAbuseReport.category,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a label', () => {
    expect(findLabel().exists()).toBe(true);
  });

  it('renders the label with the right background color for the category', () => {
    expect(findLabel().props()).toMatchObject({
      backgroundColor: category.backgroundColor,
      title: category.title,
      target: null,
    });
  });

  it('renders the label with the right text color for the category', () => {
    expect(findLabel().attributes('class')).toBe('gl-text-orange-700');
  });
});
