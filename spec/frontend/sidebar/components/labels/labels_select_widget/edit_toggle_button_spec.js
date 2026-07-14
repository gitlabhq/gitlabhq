import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EditToggleButton from '~/sidebar/components/labels/labels_select_widget/edit_toggle_button.vue';

describe('EditToggleButton', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(EditToggleButton, { propsData: props });
  };

  it('renders a GlButton with the shortcut class', () => {
    createComponent({ accessibilityAttributes: {} });
    expect(findButton().exists()).toBe(true);
    expect(findButton().classes()).toContain('shortcut-sidebar-dropdown-toggle');
    expect(findButton().attributes('data-testid')).toBe('labels-edit');
  });

  it('passes loading prop through', () => {
    createComponent({ accessibilityAttributes: {}, loading: true });
    expect(findButton().props('loading')).toBe(true);
  });

  it('spreads accessibilityAttributes onto the button', () => {
    createComponent({ accessibilityAttributes: { 'aria-haspopup': 'listbox' } });
    expect(findButton().attributes('aria-haspopup')).toBe('listbox');
  });
});
