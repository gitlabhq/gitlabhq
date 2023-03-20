import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import ToggleFocus from '~/boards/components/toggle_focus.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ToggleFocus', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ToggleFocus, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      attachTo: document.body,
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  it('renders a button with `maximize` icon', () => {
    createComponent();

    expect(findButton().props('icon')).toBe('maximize');
    expect(findButton().attributes('aria-label')).toBe(ToggleFocus.i18n.toggleFocusMode);
  });

  it('contains a tooltip with title', () => {
    createComponent();
    const tooltip = getBinding(findButton().element, 'gl-tooltip');

    expect(tooltip).toBeDefined();
    expect(findButton().attributes('title')).toBe(ToggleFocus.i18n.toggleFocusMode);
  });

  it('toggles the icon when the button is clicked', async () => {
    createComponent();
    findButton().vm.$emit('click');
    await nextTick();

    expect(findButton().props('icon')).toBe('minimize');
  });
});
