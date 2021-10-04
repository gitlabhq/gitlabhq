import { GlDropdownItem } from '@gitlab/ui';

import { shallowMount } from '@vue/test-utils';
import DeleteComponent from '~/environments/components/environment_delete.vue';
import eventHub from '~/environments/event_hub';

describe('External URL Component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(DeleteComponent, {
      propsData: {
        environment: {},
      },
    });
  };

  const findDropdownItem = () => wrapper.find(GlDropdownItem);

  beforeEach(() => {
    jest.spyOn(window, 'confirm');

    createWrapper();
  });

  it('should render a dropdown item to delete the environment', () => {
    expect(findDropdownItem().exists()).toBe(true);
    expect(wrapper.text()).toEqual('Delete environment');
    expect(findDropdownItem().attributes('variant')).toBe('danger');
  });

  it('emits requestDeleteEnvironment in the event hub when button is clicked', () => {
    jest.spyOn(eventHub, '$emit');
    findDropdownItem().vm.$emit('click');
    expect(eventHub.$emit).toHaveBeenCalledWith('requestDeleteEnvironment', wrapper.vm.environment);
  });
});
