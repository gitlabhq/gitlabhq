import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ToolbarButton from '~/vue_shared/components/markdown/toolbar_button.vue';
import {
  TOOLBAR_CONTROL_TRACKING_ACTION,
  MARKDOWN_EDITOR_TRACKING_LABEL,
} from '~/vue_shared/components/markdown/tracking';

describe('toolbar_button', () => {
  let wrapper;

  const defaultProps = {
    buttonTitle: 'test button',
    icon: 'rocket',
    tag: 'test tag',
  };

  const createComponent = (propUpdates) => {
    wrapper = shallowMount(ToolbarButton, {
      propsData: {
        ...defaultProps,
        ...propUpdates,
      },
    });
  };

  const findToolbarButton = () => wrapper.findComponent(GlButton);
  const getButtonShortcutsAttr = () => findToolbarButton().attributes('data-md-shortcuts');

  describe('keyboard shortcuts', () => {
    it.each`
      shortcutsProp              | mdShortcutsAttr
      ${undefined}               | ${JSON.stringify([])}
      ${[]}                      | ${JSON.stringify([])}
      ${'command+b'}             | ${JSON.stringify(['command+b'])}
      ${['command+b', 'ctrl+b']} | ${JSON.stringify(['command+b', 'ctrl+b'])}
    `(
      'adds the attribute data-md-shortcuts="$mdShortcutsAttr" to the button when the shortcuts prop is $shortcutsProp',
      ({ shortcutsProp, mdShortcutsAttr }) => {
        createComponent({ shortcuts: shortcutsProp });

        expect(getButtonShortcutsAttr()).toBe(mdShortcutsAttr);
      },
    );
  });

  it('adds tracking attributes to the button when `trackingProperty` prop is defined', () => {
    const buttonType = 'bold';

    createComponent({ trackingProperty: buttonType });

    expect(findToolbarButton().attributes('data-track-action')).toBe(
      TOOLBAR_CONTROL_TRACKING_ACTION,
    );
    expect(findToolbarButton().attributes('data-track-label')).toBe(MARKDOWN_EDITOR_TRACKING_LABEL);
    expect(findToolbarButton().attributes('data-track-property')).toBe(buttonType);
  });

  it('does not add tracking attributes to the button when `trackingProperty` prop is undefined', () => {
    createComponent();

    ['data-track-action', 'data-track-label', 'data-track-property'].forEach((dataAttribute) => {
      expect(findToolbarButton().attributes(dataAttribute)).toBeUndefined();
    });
  });
});
