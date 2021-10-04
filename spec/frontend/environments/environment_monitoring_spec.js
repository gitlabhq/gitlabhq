import { mountExtended } from 'helpers/vue_test_utils_helper';
import MonitoringComponent from '~/environments/components/environment_monitoring.vue';
import { __ } from '~/locale';

describe('Monitoring Component', () => {
  let wrapper;

  const monitoringUrl = 'https://gitlab.com';

  const createWrapper = () => {
    wrapper = mountExtended(MonitoringComponent, {
      propsData: {
        monitoringUrl,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('should render a link to environment monitoring page', () => {
    const link = wrapper.findByRole('menuitem', { name: __('Monitoring') });
    expect(link.attributes('href')).toEqual(monitoringUrl);
  });
});
