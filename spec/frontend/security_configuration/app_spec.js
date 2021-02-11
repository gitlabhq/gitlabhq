import { shallowMount } from '@vue/test-utils';
import App from '~/security_configuration/components/app.vue';
import ConfigurationTable from '~/security_configuration/components/configuration_table.vue';

describe('App Component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(App, {});
  };
  const findConfigurationTable = () => wrapper.findComponent(ConfigurationTable);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders correct primary & Secondary Heading', () => {
    createComponent();
    expect(wrapper.text()).toContain('Security Configuration');
    expect(wrapper.text()).toContain('Testing & Compliance');
  });

  it('renders ConfigurationTable Component', () => {
    createComponent();
    expect(findConfigurationTable().exists()).toBe(true);
  });
});
