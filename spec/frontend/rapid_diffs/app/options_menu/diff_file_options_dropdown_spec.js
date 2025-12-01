import { mount } from '@vue/test-utils';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';

describe('DiffFileOptionsDropdown', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    // mount is used because this component depends on DOM that's rendered by dropdown components
    wrapper = mount(DiffFileOptionsDropdown, { propsData });
  };

  it('shows options', () => {
    const item = { text: 'View file' };
    createComponent({ items: [item] });
    expect(wrapper.html()).toContain(item.text);
  });

  it('renders code tags', () => {
    createComponent({ items: [{ text: 'View file at %{codeStart}abc1234%{codeEnd}' }] });
    expect(wrapper.html()).toContain('<code>abc1234</code>');
  });

  it('fills text placeholders', () => {
    createComponent({
      items: [{ text: 'View file at %{placeholder}', messageData: { placeholder: 'foo' } }],
    });
    expect(wrapper.html()).toContain('View file at foo');
  });

  it('focuses toggle', () => {
    const spy = jest.spyOn(HTMLButtonElement.prototype, 'focus');
    createComponent({ items: [{ text: 'View file' }] });
    expect(spy).toHaveBeenCalled();
  });
});
