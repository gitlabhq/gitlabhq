import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

import ReportAbuseButton from '~/users/profile/components/report_abuse_button.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

describe('ReportAbuseButton', () => {
  let wrapper;

  const ACTION_PATH = '/abuse_reports/add_category';
  const USER_ID = 1;
  const REPORTED_FROM_URL = 'http://example.com';

  const createComponent = (props) => {
    wrapper = shallowMountExtended(ReportAbuseButton, {
      propsData: {
        ...props,
      },
      provide: {
        reportAbusePath: ACTION_PATH,
        reportedUserId: USER_ID,
        reportedFromUrl: REPORTED_FROM_URL,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findReportAbuseButton = () => wrapper.findComponent(GlButton);
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);

  it('renders report abuse button', () => {
    expect(findReportAbuseButton().exists()).toBe(true);

    expect(findReportAbuseButton().props()).toMatchObject({
      category: 'primary',
      icon: 'error',
    });

    expect(findReportAbuseButton().attributes('aria-label')).toBe(
      wrapper.vm.$options.i18n.reportAbuse,
    );
  });

  it('renders abuse category selector with the drawer initially closed', () => {
    expect(findAbuseCategorySelector().exists()).toBe(true);

    expect(findAbuseCategorySelector().props('showDrawer')).toBe(false);
  });

  describe('when button is clicked', () => {
    beforeEach(async () => {
      await findReportAbuseButton().vm.$emit('click');
    });

    it('opens the abuse category selector', () => {
      expect(findAbuseCategorySelector().props('showDrawer')).toBe(true);
    });

    it('closes the abuse category selector', async () => {
      await findAbuseCategorySelector().vm.$emit('close-drawer');

      expect(findAbuseCategorySelector().props('showDrawer')).toBe(false);
    });
  });

  describe('when user hovers out of the button', () => {
    it(`should emit ${BV_HIDE_TOOLTIP} to close the tooltip`, () => {
      jest.spyOn(wrapper.vm.$root, '$emit');

      findReportAbuseButton().vm.$emit('mouseout');

      expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(BV_HIDE_TOOLTIP);
    });
  });
});
