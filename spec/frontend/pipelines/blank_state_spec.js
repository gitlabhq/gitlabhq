import { mount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import BlankState from '~/pipelines/components/pipelines_list/blank_state.vue';

describe('Pipelines Blank State', () => {
  const wrapper = mount(BlankState, {
    propsData: {
      svgPath: 'foo',
      message: 'Blank State',
    },
  });

  it('should render svg', () => {
    expect(wrapper.find('.svg-content img').attributes('src')).toEqual('foo');
  });

  it('should render message', () => {
    expect(getByText(wrapper.element, /Blank State/i)).toBeTruthy();
  });
});
