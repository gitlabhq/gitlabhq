import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
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

  it('should show the label if it is set', async () => {
    wrapper.setProps({ label: 'Test label' });

    await nextTick();
    expect(wrapper.find('label').text()).toEqual('Test label');
  });

  it('should hide the label if it is not set', () => {
    expect(wrapper.find('label').exists()).toBe(false);
  });

  it('should show the help icon with the correct help path if it is set', async () => {
    wrapper.setProps({ label: 'Test label', helpPath: '/123' });

    await nextTick();
    const link = wrapper.find('a');

    expect(link.exists()).toBe(true);
    expect(link.attributes().href).toEqual('/123');
  });

  it('should hide the help icon if no help path is set', async () => {
    wrapper.setProps({ label: 'Test label' });

    await nextTick();
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('should show the help text if it is set', async () => {
    wrapper.setProps({ helpText: 'Test text' });

    await nextTick();
    expect(wrapper.find('span').text()).toEqual('Test text');
  });

  it('should hide the help text if it is set', () => {
    expect(wrapper.find('span').exists()).toBe(false);
  });
});
