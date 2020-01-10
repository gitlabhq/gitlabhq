import { shallowMount } from '@vue/test-utils';
import functionRowComponent from '~/serverless/components/function_row.vue';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockServerlessFunction } from '../mock_data';

describe('functionRowComponent', () => {
  let wrapper;

  const createComponent = func => {
    wrapper = shallowMount(functionRowComponent, {
      propsData: { func },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Parses the function details correctly', () => {
    createComponent(mockServerlessFunction);

    expect(wrapper.find('b').text()).toBe(mockServerlessFunction.name);
    expect(wrapper.find('span').text()).toBe(mockServerlessFunction.image);
    expect(wrapper.find(Timeago).attributes('time')).not.toBe(null);
  });

  it('handles clicks correctly', () => {
    createComponent(mockServerlessFunction);
    const { vm } = wrapper;

    expect(vm.checkClass(vm.$el.querySelector('p'))).toBe(true); // check somewhere inside the row
  });
});
