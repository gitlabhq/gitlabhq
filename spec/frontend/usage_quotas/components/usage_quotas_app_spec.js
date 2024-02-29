import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UsageQuotasApp from '~/usage_quotas/components/usage_quotas_app.vue';
import { defaultProvide } from '../mock_data';

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

  beforeEach(() => {
    createComponent();
  });

  const findGlAlert = () => wrapper.findComponent(GlAlert);

  describe('when tabs array is empty', () => {
    it('shows error alert', () => {
      expect(findGlAlert().text()).toContain(
        'Something went wrong while loading Usage Quotas Tabs',
      );
    });
  });
});
