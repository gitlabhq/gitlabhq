import { GlAlert, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AlertDeprecationWarning from '~/vue_shared/components/alerts_deprecation_warning.vue';

describe('AlertDetails', () => {
  let wrapper;

  function mountComponent(hasManagedPrometheus = false) {
    wrapper = mount(AlertDeprecationWarning, {
      provide: {
        hasManagedPrometheus,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  describe('Alert details', () => {
    describe('with no manual prometheus', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('renders nothing', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('with manual prometheus', () => {
      beforeEach(() => {
        mountComponent(true);
      });

      it('renders a deprecation notice', () => {
        expect(findAlert().text()).toContain('GitLab-managed Prometheus is deprecated');
        expect(findLink().attributes('href')).toContain(
          'operations/metrics/alerts.html#managed-prometheus-instances',
        );
      });
    });
  });
});
