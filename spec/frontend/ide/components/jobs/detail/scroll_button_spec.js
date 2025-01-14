import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ScrollButton from '~/ide/components/jobs/detail/scroll_button.vue';

describe('IDE job log scroll button', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(ScrollButton, {
      propsData: {
        direction: 'up',
        disabled: false,
        ...props,
      },
    });
  };

  describe.each`
    direction | icon             | title
    ${'up'}   | ${'scroll_up'}   | ${'Scroll to top'}
    ${'down'} | ${'scroll_down'} | ${'Scroll to bottom'}
  `('for $direction direction', ({ direction, icon, title }) => {
    beforeEach(() => createComponent({ direction }));

    it('returns proper icon name', () => {
      expect(wrapper.findComponent(GlIcon).props('name')).toBe(icon);
    });

    it('returns proper title', () => {
      expect(wrapper.attributes('title')).toBe(title);
    });
  });

  it('emits click event on click', () => {
    createComponent();

    wrapper.findComponent(GlButton).vm.$emit('click');
    expect(wrapper.emitted().click).toBeDefined();
  });

  it('disables button when disabled is true', () => {
    createComponent({ disabled: true });

    expect(wrapper.findComponent(GlButton).attributes('disabled')).toBeDefined();
  });
});
