import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';
import {
  CLICK_TAB_ON_MERGE_REQUEST_REPORT,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';

describe('ReportListItem', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ReportListItem, {
      propsData: {
        to: 'security-scan',
        statusIcon: 'success',
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
    });
  };

  const findRouterLink = () => wrapper.findComponent(RouterLinkStub);

  describe('tracking', () => {
    it('has tracking attributes', () => {
      createComponent();

      expect(findRouterLink().attributes()).toMatchObject({
        'data-event-tracking': CLICK_TAB_ON_MERGE_REQUEST_REPORT,
        'data-event-label': TRACKING_LABEL_BY_ROUTE['security-scan'],
      });
    });
  });
});
