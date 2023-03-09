import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UsageQuotasApp from '~/usage_quotas/components/usage_quotas_app.vue';
import { USAGE_QUOTAS_TITLE } from '~/usage_quotas/constants';
import { defaultProvide } from '../mock_data';

describe('UsageQuotasApp', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(UsageQuotasApp, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findSubTitle = () => wrapper.findByTestId('usage-quotas-page-subtitle');

  it('renders the view title', () => {
    expect(wrapper.text()).toContain(USAGE_QUOTAS_TITLE);
  });

  it('renders the view subtitle', () => {
    expect(findSubTitle().text()).toContain(defaultProvide.namespaceName);
  });
});
