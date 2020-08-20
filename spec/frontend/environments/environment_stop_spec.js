import $ from 'jquery';
import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import StopComponent from '~/environments/components/environment_stop.vue';
import eventHub from '~/environments/event_hub';

$.fn.tooltip = () => {};

describe('Stop Component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(StopComponent, {
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

  it('should render a button to stop the environment', () => {
    expect(findButton().exists()).toBe(true);
    expect(wrapper.attributes('title')).toEqual('Stop environment');
  });

  it('emits requestStopEnvironment in the event hub when button is clicked', () => {
    jest.spyOn(eventHub, '$emit');
    findButton().vm.$emit('click');
    expect(eventHub.$emit).toHaveBeenCalledWith('requestStopEnvironment', wrapper.vm.environment);
  });
});
