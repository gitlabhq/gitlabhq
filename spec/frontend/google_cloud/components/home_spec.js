import { shallowMount } from '@vue/test-utils';
import { GlTab, GlTabs } from '@gitlab/ui';
import Home from '~/google_cloud/components/home.vue';
import ServiceAccountsList from '~/google_cloud/components/service_accounts_list.vue';

describe('google_cloud Home component', () => {
  let wrapper;

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTabItems = () => findTabs().findAllComponents(GlTab);
  const findTabItemsModel = () =>
    findTabs()
      .findAllComponents(GlTab)
      .wrappers.map((x) => ({
        title: x.attributes('title'),
        disabled: x.attributes('disabled'),
      }));

  const TEST_HOME_PROPS = {
    serviceAccounts: [{}, {}],
    createServiceAccountUrl: '#url-create-service-account',
    emptyIllustrationUrl: '#url-empty-illustration',
    deploymentsCloudRunUrl: '#url-deployments-cloud-run',
    deploymentsCloudStorageUrl: '#deploymentsCloudStorageUrl',
  };

  beforeEach(() => {
    const propsData = {
      screen: 'home',
      ...TEST_HOME_PROPS,
    };
    wrapper = shallowMount(Home, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('google_cloud App tabs', () => {
    it('should contain tabs', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('should contain three tab items', () => {
      expect(findTabItemsModel()).toEqual([
        { title: 'Configuration', disabled: undefined },
        { title: 'Deployments', disabled: undefined },
        { title: 'Services', disabled: '' },
      ]);
    });

    describe('configuration tab', () => {
      it('should contain service accounts component', () => {
        const serviceAccounts = findTabItems().at(0).findComponent(ServiceAccountsList);
        expect(serviceAccounts.props()).toEqual({
          list: TEST_HOME_PROPS.serviceAccounts,
          createUrl: TEST_HOME_PROPS.createServiceAccountUrl,
          emptyIllustrationUrl: TEST_HOME_PROPS.emptyIllustrationUrl,
        });
      });
    });
  });
});
