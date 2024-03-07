import { GlEmptyState, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EmptyStateWithoutAnyIssues from '~/issues/service_desk/components/empty_state_without_any_issues.vue';
import {
  infoBannerTitle,
  noIssuesSignedOutButtonText,
  learnMore,
} from '~/issues/service_desk/constants';

describe('EmptyStateWithoutAnyIssues component', () => {
  let wrapper;

  const defaultProvide = {
    emptyStateSvgPath: 'empty/state/svg/path',
    isSignedIn: true,
    signInPath: 'sign/in/path',
    canAdminIssues: true,
    isServiceDeskEnabled: true,
    serviceDeskEmailAddress: 'email@address.com',
    serviceDeskHelpPath: 'service/desk/help/path',
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findIssuesHelpPageLink = () => wrapper.findByRole('link', { name: learnMore });

  const mountComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(EmptyStateWithoutAnyIssues, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  describe('when signed in', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: infoBannerTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });

    it('renders description with service desk docs link', () => {
      expect(findIssuesHelpPageLink().attributes('href')).toBe(defaultProvide.serviceDeskHelpPath);
    });

    it('renders email address, when user can admin issues and service desk is enabled', () => {
      expect(wrapper.text()).toContain(wrapper.vm.serviceDeskEmailAddress);
    });

    it('does not render email address, when user can not admin issues', () => {
      mountComponent({ provide: { canAdminIssues: false } });

      expect(wrapper.text()).not.toContain(wrapper.vm.serviceDeskEmailAddress);
    });

    it('does not render email address, when service desk is not setup', () => {
      mountComponent({ provide: { isServiceDeskEnabled: false } });

      expect(wrapper.text()).not.toContain(wrapper.vm.serviceDeskEmailAddress);
    });
  });

  describe('when signed out', () => {
    beforeEach(() => {
      mountComponent({ provide: { isSignedIn: false } });
    });

    it('renders empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: infoBannerTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
        primaryButtonText: noIssuesSignedOutButtonText,
        primaryButtonLink: defaultProvide.signInPath,
      });
    });

    it('renders service desk docs link', () => {
      expect(findGlLink().attributes('href')).toBe(defaultProvide.serviceDeskHelpPath);
      expect(findGlLink().text()).toBe(learnMore);
    });
  });
});
