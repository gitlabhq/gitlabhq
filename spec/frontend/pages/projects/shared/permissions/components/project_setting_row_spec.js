import { shallowMount } from '@vue/test-utils';

import projectSettingRow from '~/pages/projects/shared/permissions/components/project_setting_row.vue';

describe('Project Setting Row', () => {
  let wrapper;

  const mountComponent = (customProps = {}) => {
    const propsData = { ...customProps };
    return shallowMount(projectSettingRow, { propsData });
  };

  beforeEach(() => {
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should show the label if it is set', () => {
    wrapper.setProps({ label: 'Test label' });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('label').text()).toEqual('Test label');
    });
  });

  it('should hide the label if it is not set', () => {
    expect(wrapper.find('label').exists()).toBe(false);
  });

  it('should show the help icon with the correct help path if it is set', () => {
    wrapper.setProps({ label: 'Test label', helpPath: '/123' });

    return wrapper.vm.$nextTick(() => {
      const link = wrapper.find('a');

      expect(link.exists()).toBe(true);
      expect(link.attributes().href).toEqual('/123');
    });
  });

  it('should hide the help icon if no help path is set', () => {
    wrapper.setProps({ label: 'Test label' });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('a').exists()).toBe(false);
    });
  });

  it('should show the help text if it is set', () => {
    wrapper.setProps({ helpText: 'Test text' });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('span').text()).toEqual('Test text');
    });
  });

  it('should hide the help text if it is set', () => {
    expect(wrapper.find('span').exists()).toBe(false);
  });
});
