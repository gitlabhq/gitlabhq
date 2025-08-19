import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ExpandCollapseButton from '~/projects/commits/components/expand_collapse_button.vue';

describe('ExpandCollapseButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ExpandCollapseButton, {
      propsData: {
        isCollapsed: true,
        ...props,
      },
      stubs: {
        GlButton,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findExpandCollapseButton = () => wrapper.findComponent(ExpandCollapseButton);

  describe('when isCollapsed is true', () => {
    it('shows expand button', () => {
      expect(findExpandCollapseButton().attributes('aria-label')).toBe('Expand');
      expect(findExpandCollapseButton().attributes('aria-expanded')).toBe('false');
    });

    it('emits click event when expand button is clicked', async () => {
      await findExpandCollapseButton().vm.$emit('click');
      expect(wrapper.emitted()).toEqual({ click: [[]] });
    });
  });

  describe('when isCollapsed is false', () => {
    beforeEach(() => {
      createComponent({ isCollapsed: false });
    });

    it('shows collapse button', () => {
      expect(findExpandCollapseButton().attributes('aria-label')).toBe('Collapse');
      expect(findExpandCollapseButton().attributes('aria-expanded')).toBe('true');
    });

    it('emits click event when collapse button is clicked', async () => {
      await findExpandCollapseButton().vm.$emit('click');
      expect(wrapper.emitted()).toEqual({ click: [[]] });
    });
  });
});
