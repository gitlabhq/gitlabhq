import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ServicePingDisabled from '~/analytics/devops_reports/components/service_ping_disabled.vue';

describe('~/analytics/devops_reports/components/service_ping_disabled.vue', () => {
  let wrapper;

  const createWrapper = ({ isAdmin = false } = {}) => {
    wrapper = mountExtended(ServicePingDisabled, {
      provide: {
        isAdmin,
        svgPath: TEST_HOST,
        primaryButtonPath: TEST_HOST,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findMessageForRegularUsers = () => wrapper.findComponent(GlSprintf);
  const findDocsLink = () => wrapper.findByRole('link', { name: 'service ping' });
  const findPowerOnButton = () => wrapper.findByRole('link', { name: 'Turn on service ping' });

  it('renders empty state with provided SVG path', () => {
    createWrapper();

    expect(findEmptyState().props('svgPath')).toBe(TEST_HOST);
  });

  describe('for regular users', () => {
    beforeEach(() => {
      createWrapper({ isAdmin: false });
    });

    it('renders message without power-on button', () => {
      expect(findMessageForRegularUsers().exists()).toBe(true);
      expect(findPowerOnButton().exists()).toBe(false);
    });

    it('renders docs link', () => {
      expect(findDocsLink().exists()).toBe(true);
      expect(findDocsLink().attributes('href')).toBe(
        '/help/development/internal_analytics/service_ping/_index',
      );
    });
  });

  describe('for admins', () => {
    beforeEach(() => {
      createWrapper({ isAdmin: true });
    });

    it('renders power-on button', () => {
      expect(findPowerOnButton().exists()).toBe(true);
    });
  });
});
