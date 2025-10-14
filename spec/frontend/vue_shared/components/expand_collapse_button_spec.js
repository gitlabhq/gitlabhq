import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ExpandCollapseButton from '~/vue_shared/components/expand_collapse_button/expand_collapse_button.vue';

describe('ExpandCollapseButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ExpandCollapseButton, {
      propsData: {
        isCollapsed: true,
        accessibleLabel: 'Address review comments',
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
      expect(findExpandCollapseButton().attributes('aria-label')).toBe(
        'Expand Address review comments',
      );
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
      expect(findExpandCollapseButton().attributes('aria-label')).toBe(
        'Collapse Address review comments',
      );
      expect(findExpandCollapseButton().attributes('aria-expanded')).toBe('true');
    });

    it('emits click event when collapse button is clicked', async () => {
      await findExpandCollapseButton().vm.$emit('click');
      expect(wrapper.emitted()).toEqual({ click: [[]] });
    });
  });
});
