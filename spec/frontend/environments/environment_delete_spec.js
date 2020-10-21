import { GlButton } from '@gitlab/ui';

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

  const findButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    jest.spyOn(window, 'confirm');

    createWrapper();
  });

  it('should render a button to delete the environment', () => {
    expect(findButton().exists()).toBe(true);
    expect(wrapper.attributes('title')).toEqual('Delete environment');
  });

  it('emits requestDeleteEnvironment in the event hub when button is clicked', () => {
    jest.spyOn(eventHub, '$emit');
    findButton().vm.$emit('click');
    expect(eventHub.$emit).toHaveBeenCalledWith('requestDeleteEnvironment', wrapper.vm.environment);
  });
});
