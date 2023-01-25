import { nextTick } from 'vue';
import { GlDropdownItem } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ReportAbuseDropdownItem from '~/projects/report_abuse/components/report_abuse_dropdown_item.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

describe('ReportAbuseDropdownItem', () => {
  let wrapper;

  const ACTION_PATH = '/abuse_reports/add_category';
  const USER_ID = 1;
  const REPORTED_FROM_URL = 'http://example.com';

  const createComponent = (props) => {
    wrapper = shallowMountExtended(ReportAbuseDropdownItem, {
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

  const findReportAbuseItem = () => wrapper.findComponent(GlDropdownItem);
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findMountingPortal = () => wrapper.findComponent(MountingPortal);

  it('renders report abuse dropdown item', () => {
    expect(findReportAbuseItem().text()).toBe(ReportAbuseDropdownItem.i18n.reportAbuse);
  });

  it('renders abuse category selector with the drawer initially closed', () => {
    expect(findAbuseCategorySelector().exists()).toBe(true);

    expect(findAbuseCategorySelector().props('showDrawer')).toBe(false);
  });

  it('renders abuse category selector inside MountingPortal', () => {
    expect(findMountingPortal().props()).toMatchObject({
      mountTo: '#js-report-abuse-drawer',
      append: true,
      name: 'abuse-category-selector',
    });
  });

  describe('when dropdown item is clicked', () => {
    beforeEach(() => {
      findReportAbuseItem().vm.$emit('click');
      return nextTick();
    });

    it('opens the abuse category selector', () => {
      expect(findAbuseCategorySelector().props('showDrawer')).toBe(true);
    });

    it('closes the abuse category selector', async () => {
      findAbuseCategorySelector().vm.$emit('close-drawer');

      await nextTick();

      expect(findAbuseCategorySelector().props('showDrawer')).toBe(false);
    });
  });
});
