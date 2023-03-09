import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

describe('Settings Block', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = shallowMountExtended(SettingsBlock, {
      propsData,
      slots: {
        title: '<div data-testid="title-slot"></div>',
        description: '<div data-testid="description-slot"></div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findTitleSlot = () => wrapper.findByTestId('title-slot');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');
  const findExpandButton = () => wrapper.findComponent(GlButton);
  const findSectionTitleButton = () => wrapper.findByTestId('section-title-button');
  // we are using a non js class for this finder because this class determine the component structure
  const findSettingsContent = () => wrapper.find('.settings-content');

  const expectExpandedState = ({ expanded = true } = {}) => {
    const settingsExpandButton = findExpandButton();

    expect(wrapper.classes('expanded')).toBe(expanded);
    expect(settingsExpandButton.text()).toBe(
      expanded ? SettingsBlock.i18n.collapseText : SettingsBlock.i18n.expandText,
    );
    expect(settingsExpandButton.attributes('aria-label')).toBe(
      expanded ? SettingsBlock.i18n.collapseAriaLabel : SettingsBlock.i18n.expandAriaLabel,
    );
  };

  it('renders the correct markup', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('has a title slot', () => {
    mountComponent();

    expect(findTitleSlot().exists()).toBe(true);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });

  it('content is hidden before first expansion', async () => {
    // this is a regression test for the bug described here: https://gitlab.com/gitlab-org/gitlab/-/issues/331774
    mountComponent();

    // content is hidden
    expect(findDefaultSlot().isVisible()).toBe(false);

    // expand
    await findSectionTitleButton().trigger('click');

    // content is visible
    expect(findDefaultSlot().isVisible()).toBe(true);

    // collapse
    await findSectionTitleButton().trigger('click');

    // content is still visible (and we have a closing animation)
    expect(findDefaultSlot().isVisible()).toBe(true);
  });

  describe('slide animation behaviour', () => {
    it('is animated by default', () => {
      mountComponent();

      expect(wrapper.classes('no-animate')).toBe(false);
    });

    it.each`
      slideAnimated | noAnimatedClass
      ${true}       | ${false}
      ${false}      | ${true}
    `(
      'sets the correct state when slideAnimated is $slideAnimated',
      ({ slideAnimated, noAnimatedClass }) => {
        mountComponent({ slideAnimated });

        expect(wrapper.classes('no-animate')).toBe(noAnimatedClass);
      },
    );

    it('sets the animating class only during the animation', async () => {
      mountComponent();

      expect(wrapper.classes('animating')).toBe(false);

      await findSectionTitleButton().trigger('click');

      expect(wrapper.classes('animating')).toBe(true);

      await findSettingsContent().trigger('animationend');

      expect(wrapper.classes('animating')).toBe(false);
    });
  });

  describe('expanded behaviour', () => {
    it('is collapsed by default', () => {
      mountComponent();

      expectExpandedState({ expanded: false });
    });

    it('adds expanded class when the expand button is clicked', async () => {
      mountComponent();

      await findExpandButton().vm.$emit('click');

      expectExpandedState({ expanded: true });
    });

    it('adds expanded class when the section title is clicked', async () => {
      mountComponent();

      await findSectionTitleButton().trigger('click');

      expectExpandedState({ expanded: true });
    });

    describe('when `collapsible` is `false`', () => {
      beforeEach(() => {
        mountComponent({ collapsible: false });
      });

      it('does not render clickable section title', () => {
        expect(findSectionTitleButton().exists()).toBe(false);
      });

      it('contains expanded class', () => {
        expect(wrapper.classes('expanded')).toBe(true);
      });

      it('does not render expand toggle button', () => {
        expect(findExpandButton().exists()).toBe(false);
      });
    });
  });
});
