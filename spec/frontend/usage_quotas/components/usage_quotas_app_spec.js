import { GlAlert, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UsageQuotasApp from '~/usage_quotas/components/usage_quotas_app.vue';
import Tracking from '~/tracking';
import { defaultProvide, provideWithTabs } from '../mock_data';

describe('UsageQuotasApp', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(UsageQuotasApp, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findTabs = () => wrapper.findAllComponents(GlTab);

  describe('when tabs array is empty', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows error alert', () => {
      expect(findGlAlert().text()).toContain(
        'Something went wrong while loading Usage Quotas Tabs',
      );
    });
  });

  describe('when there are tabs', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      createComponent({
        provide: provideWithTabs,
      });
    });

    it('does not show error alert', () => {
      expect(findGlAlert().exists()).toBe(false);
    });

    it('tracks internal events when user clicks on a tab that has tracking data', () => {
      findTabs().at(0).vm.$emit('click');

      expect(Tracking.event).toHaveBeenCalledWith(
        undefined,
        provideWithTabs.tabs[0].tracking.action,
        expect.any(Object),
      );
    });

    it('does not track any event when user clicks on a tab that does not have tracking data', () => {
      findTabs().at(1).vm.$emit('click');

      expect(Tracking.event).not.toHaveBeenCalledWith();
    });
  });
});
