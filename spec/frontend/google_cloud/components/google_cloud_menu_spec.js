import { mountExtended } from 'helpers/vue_test_utils_helper';
import GoogleCloudMenu from '~/google_cloud/components/google_cloud_menu.vue';

describe('google_cloud/components/google_cloud_menu', () => {
  let wrapper;

  const props = {
    active: 'configuration',
    configurationUrl: 'configuration-url',
    deploymentsUrl: 'deployments-url',
    databasesUrl: 'databases-url',
    aimlUrl: 'aiml-url',
  };

  beforeEach(() => {
    wrapper = mountExtended(GoogleCloudMenu, { propsData: props });
  });

  it('contains active configuration link', () => {
    const link = wrapper.findByTestId('configurationLink');
    expect(link.text()).toBe(GoogleCloudMenu.i18n.configuration.title);
    expect(link.attributes('href')).toBe(props.configurationUrl);
    expect(link.element.classList.contains('gl-tab-nav-item-active')).toBe(true);
  });

  it('contains deployments link', () => {
    const link = wrapper.findByTestId('deploymentsLink');
    expect(link.text()).toBe(GoogleCloudMenu.i18n.deployments.title);
    expect(link.attributes('href')).toBe(props.deploymentsUrl);
  });

  it('contains databases link', () => {
    const link = wrapper.findByTestId('databasesLink');
    expect(link.text()).toBe(GoogleCloudMenu.i18n.databases.title);
    expect(link.attributes('href')).toBe(props.databasesUrl);
  });

  it('contains ai/ml link', () => {
    const link = wrapper.findByTestId('aimlLink');
    expect(link.text()).toBe(GoogleCloudMenu.i18n.aiml.title);
    expect(link.attributes('href')).toBe(props.aimlUrl);
  });
});
