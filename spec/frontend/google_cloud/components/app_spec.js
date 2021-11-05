import { shallowMount } from '@vue/test-utils';
import { GlTab, GlTabs } from '@gitlab/ui';
import App from '~/google_cloud/components/app.vue';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import ServiceAccounts from '~/google_cloud/components/service_accounts.vue';

describe('google_cloud App component', () => {
  let wrapper;

  const findIncubationBanner = () => wrapper.findComponent(IncubationBanner);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTabItems = () => findTabs().findAllComponents(GlTab);
  const findConfigurationTab = () => findTabItems().at(0);
  const findDeploymentTab = () => findTabItems().at(1);
  const findServicesTab = () => findTabItems().at(2);
  const findServiceAccounts = () => findConfigurationTab().findComponent(ServiceAccounts);

  beforeEach(() => {
    const propsData = {
      serviceAccounts: [{}, {}],
      createServiceAccountUrl: '#url-create-service-account',
      emptyIllustrationUrl: '#url-empty-illustration',
    };
    wrapper = shallowMount(App, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should contain incubation banner', () => {
    expect(findIncubationBanner().exists()).toBe(true);
  });

  describe('google_cloud App tabs', () => {
    it('should contain tabs', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('should contain three tab items', () => {
      expect(findTabItems().length).toBe(3);
    });

    describe('configuration tab', () => {
      it('should exist', () => {
        expect(findConfigurationTab().exists()).toBe(true);
      });

      it('should contain service accounts component', () => {
        expect(findServiceAccounts().exists()).toBe(true);
      });
    });

    describe('deployments tab', () => {
      it('should exist', () => {
        expect(findDeploymentTab().exists()).toBe(true);
      });
    });

    describe('services tab', () => {
      it('should exist', () => {
        expect(findServicesTab().exists()).toBe(true);
      });
    });
  });
});
