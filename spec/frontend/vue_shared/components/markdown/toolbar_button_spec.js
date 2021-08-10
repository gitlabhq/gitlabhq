import { shallowMount } from '@vue/test-utils';
import ToolbarButton from '~/vue_shared/components/markdown/toolbar_button.vue';

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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const getButtonShortcutsAttr = () => {
    return wrapper.find('button').attributes('data-md-shortcuts');
  };

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
});
