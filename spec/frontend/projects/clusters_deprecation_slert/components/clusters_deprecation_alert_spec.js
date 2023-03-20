import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ClustersDeprecationAlert from '~/projects/clusters_deprecation_alert/components/clusters_deprecation_alert.vue';

const message = 'Alert message';

describe('ClustersDeprecationAlert', () => {
  let wrapper;

  const provideData = {
    message,
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = () => {
    wrapper = shallowMount(ClustersDeprecationAlert, {
      provide: provideData,
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('should render a non-dismissible warning alert', () => {
      expect(findAlert().props()).toMatchObject({
        dismissible: false,
        variant: 'warning',
      });
    });

    it('should display the correct message', () => {
      expect(findAlert().text()).toBe(message);
    });
  });
});
