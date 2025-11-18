import { shallowMount } from '@vue/test-utils';
import BlameLegend from '~/blame/blame_legend.vue';

describe('BlameLegend', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BlameLegend);
  };

  it('renders 10 legend boxes', () => {
    createComponent();
    const legendBoxes = wrapper.findAll('.legend-box');
    expect(legendBoxes).toHaveLength(10);
  });

  it('hides blame indicators from screen readers', () => {
    createComponent();
    expect(wrapper.attributes('aria-hidden')).toBe('true');
  });
});
