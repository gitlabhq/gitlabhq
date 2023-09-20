import { shallowMount } from '@vue/test-utils';
import { GlLink, GlButton } from '@gitlab/ui';
import InfoBanner from '~/issues/service_desk/components/info_banner.vue';
import { infoBannerAdminNote, enableServiceDesk } from '~/issues/service_desk/constants';

describe('InfoBanner', () => {
  let wrapper;

  const defaultProvide = {
    serviceDeskCalloutSvgPath: 'callout.svg',
    serviceDeskEmailAddress: 'sd@gmail.com',
    canAdminIssues: true,
    canEditProjectSettings: true,
    serviceDeskSettingsPath: 'path/to/project/settings',
    serviceDeskHelpPath: 'path/to/documentation',
    isServiceDeskEnabled: true,
  };

  const findEnableSDButton = () => wrapper.findComponent(GlButton);

  const mountComponent = (provide) => {
    return shallowMount(InfoBanner, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlLink,
        GlButton,
      },
    });
  };

  beforeEach(() => {
    wrapper = mountComponent();
  });

  describe('Service Desk email address', () => {
    it('renders when user can admin issues and service desk is enabled', () => {
      expect(wrapper.text()).toContain(infoBannerAdminNote);
      expect(wrapper.text()).toContain(wrapper.vm.serviceDeskEmailAddress);
    });

    it('does not render, when user can not admin issues', () => {
      wrapper = mountComponent({ canAdminIssues: false });

      expect(wrapper.text()).not.toContain(infoBannerAdminNote);
      expect(wrapper.text()).not.toContain(wrapper.vm.serviceDeskEmailAddress);
    });

    it('does not render, when service desk is not setup', () => {
      wrapper = mountComponent({ isServiceDeskEnabled: false });

      expect(wrapper.text()).not.toContain(infoBannerAdminNote);
      expect(wrapper.text()).not.toContain(wrapper.vm.serviceDeskEmailAddress);
    });
  });

  describe('Link to Service Desk settings', () => {
    it('renders when user can edit settings and service desk is not enabled', () => {
      wrapper = mountComponent({ isServiceDeskEnabled: false });

      expect(wrapper.text()).toContain(enableServiceDesk);
      expect(findEnableSDButton().exists()).toBe(true);
    });

    it('does not render when service desk is enabled', () => {
      wrapper = mountComponent();

      expect(wrapper.text()).not.toContain(enableServiceDesk);
      expect(findEnableSDButton().exists()).toBe(false);
    });

    it('does not render when user cannot edit settings', () => {
      wrapper = mountComponent({ canEditProjectSettings: false });

      expect(wrapper.text()).not.toContain(enableServiceDesk);
      expect(findEnableSDButton().exists()).toBe(false);
    });
  });
});
