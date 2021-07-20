import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ServicePingDisabled from '~/analytics/devops_report/components/service_ping_disabled.vue';

describe('~/analytics/devops_report/components/service_ping_disabled.vue', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const createWrapper = ({ isAdmin = false } = {}) => {
    wrapper = shallowMountExtended(ServicePingDisabled, {
      provide: {
        isAdmin,
        svgPath: TEST_HOST,
        docsLink: TEST_HOST,
        primaryButtonPath: TEST_HOST,
      },
      stubs: { GlEmptyState, GlSprintf },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findMessageForRegularUsers = () => wrapper.findComponent(GlSprintf);
  const findDocsLink = () => wrapper.findByTestId('docs-link');
  const findPowerOnButton = () => wrapper.findByTestId('power-on-button');

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
      expect(findDocsLink().attributes('href')).toBe(TEST_HOST);
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
