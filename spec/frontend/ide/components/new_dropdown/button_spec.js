import { mount } from '@vue/test-utils';
import Button from '~/ide/components/new_dropdown/button.vue';

describe('IDE new entry dropdown button component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(Button, {
      propsData: {
        label: 'Testing',
        icon: 'doc-new',
        ...props,
      },
    });
  };

  it('renders button with label', () => {
    createComponent();

    expect(wrapper.text()).toContain('Testing');
  });

  it('renders icon', () => {
    createComponent();

    expect(wrapper.find('[data-testid="doc-new-icon"]').exists()).toBe(true);
  });

  it('emits click event', async () => {
    createComponent();

    await wrapper.trigger('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });

  it('hides label if showLabel is false', () => {
    createComponent({ showLabel: false });

    expect(wrapper.text()).not.toContain('Testing');
  });

  describe('tooltip title', () => {
    it('returns empty string when showLabel is true', () => {
      createComponent({ showLabel: true });

      expect(wrapper.attributes('title')).toBe('');
    });

    it('returns label', () => {
      createComponent({ showLabel: false });

      expect(wrapper.attributes('title')).toBe('Testing');
    });
  });
});
