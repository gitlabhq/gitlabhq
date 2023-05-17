import { shallowMount } from '@vue/test-utils';
import Prompt from '~/notebook/cells/prompt.vue';

describe('Prompt component', () => {
  let wrapper;

  const mountComponent = ({ type }) => shallowMount(Prompt, { propsData: { type, count: 1 } });

  describe('input', () => {
    beforeEach(() => {
      wrapper = mountComponent({ type: 'In' });
    });

    it('renders in label', () => {
      expect(wrapper.text()).toContain('In');
    });

    it('renders count', () => {
      expect(wrapper.text()).toContain('1');
    });
  });

  describe('output', () => {
    beforeEach(() => {
      wrapper = mountComponent({ type: 'Out' });
    });

    it('renders in label', () => {
      expect(wrapper.text()).toContain('Out');
    });

    it('renders count', () => {
      expect(wrapper.text()).toContain('1');
    });
  });
});
