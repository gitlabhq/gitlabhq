import functionRowComponent from '~/serverless/components/function_row.vue';
import { shallowMount } from '@vue/test-utils';

import { mockServerlessFunction } from '../mock_data';

const createComponent = func =>
  shallowMount(functionRowComponent, { propsData: { func }, sync: false }).vm;

describe('functionRowComponent', () => {
  it('Parses the function details correctly', () => {
    const vm = createComponent(mockServerlessFunction);

    expect(vm.$el.querySelector('b').innerHTML).toEqual(mockServerlessFunction.name);
    expect(vm.$el.querySelector('span').innerHTML).toEqual(mockServerlessFunction.image);
    expect(vm.$el.querySelector('timeago-stub').getAttribute('time')).not.toBe(null);

    vm.$destroy();
  });

  it('handles clicks correctly', () => {
    const vm = createComponent(mockServerlessFunction);

    expect(vm.checkClass(vm.$el.querySelector('p'))).toBe(true); // check somewhere inside the row

    vm.$destroy();
  });
});
