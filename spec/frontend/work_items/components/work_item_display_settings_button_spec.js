import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemDisplaySettingsButton from '~/work_items/components/work_item_display_settings_button.vue';

describe('WorkItemDisplaySettingsButton', () => {
  let wrapper;

  const findIconButton = () => wrapper.findComponentByTestId('display-settings-icon-button');
  const findLabelButton = () => wrapper.findComponentByTestId('display-settings-label-button');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsButton, { propsData: props });
  };

  it('renders an icon-only button with a tooltip, hidden from the md breakpoint up', () => {
    createComponent();

    expect(findIconButton().props('icon')).toBe('preferences');
    expect(findIconButton().text()).toBe('');
    expect(findIconButton().attributes('title')).toBe('Display');
    expect(findIconButton().attributes('aria-label')).toBe('Display');
    expect(findIconButton().classes()).toContain('@md/panel:gl-hidden');
  });

  it('renders an icon and text button, hidden below the md breakpoint', () => {
    createComponent();

    expect(findLabelButton().props('icon')).toBe('preferences');
    expect(findLabelButton().text()).toBe('Display');
    expect(findLabelButton().classes()).toEqual(
      expect.arrayContaining(['gl-hidden', '@md/panel:gl-inline-flex']),
    );
  });

  it.each([true, false])('passes selected=%s to both buttons', (selected) => {
    createComponent({ props: { selected } });

    expect(findIconButton().props('selected')).toBe(selected);
    expect(findLabelButton().props('selected')).toBe(selected);
  });

  it.each`
    variant    | findButton
    ${'icon'}  | ${findIconButton}
    ${'label'} | ${findLabelButton}
  `('emits click when the $variant button is clicked', ({ findButton }) => {
    createComponent();

    findButton().vm.$emit('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
