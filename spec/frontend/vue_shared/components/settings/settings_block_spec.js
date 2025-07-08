import { GlCollapse, GlAnimatedChevronLgRightDownIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import { parseBoolean } from '~/lib/utils/common_utils';

describe('Settings Block', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = mountExtended(SettingsBlock, {
      propsData,
      title: 'Advanced',
      slots: {
        description: '<div data-testid="description-slot"></div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findTitle = () => wrapper.findByTestId('settings-block-title');
  const findToggleButton = () => wrapper.findByTestId('settings-block-toggle');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');
  const findChevronIcon = () => wrapper.findComponent(GlAnimatedChevronLgRightDownIcon);

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('has a title slot', () => {
    mountComponent();

    expect(findTitle().exists()).toBe(true);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });

  describe('when `expanded` prop is `false` and URL hash does not match `id`', () => {
    it('renders collapse as closed', () => {
      mountComponent();

      expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(false);
    });
  });

  describe('when `expanded` prop is `true`', () => {
    it('renders collapse as expanded', () => {
      mountComponent({ expanded: true });

      expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(true);
    });
  });

  describe('when URL hash matches `id`', () => {
    it('renders collapse as expanded', () => {
      setWindowLocation('https://gitlab.test/#foo-bar');

      mountComponent({ id: 'foo-bar' });

      expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(true);
    });
  });

  describe('when collapse is closed', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders button with `Expand` text', () => {
      expect(findToggleButton().attributes('aria-label')).toContain('Expand');
    });

    it('animates chevron', () => {
      // Vue compat doesn't know about component props if it extends other component
      expect(
        findChevronIcon().props('isOn') ?? parseBoolean(findChevronIcon().attributes('is-on')),
      ).toBe(false);
    });

    describe('when `Expand` button is clicked', () => {
      beforeEach(async () => {
        await findToggleButton().trigger('click');
      });

      it('expands the collapse', () => {
        expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(true);
      });

      it('emits `toggle-expand` event', () => {
        expect(wrapper.emitted('toggle-expand')).toEqual([[true]]);
      });
    });

    describe('when title is clicked', () => {
      beforeEach(async () => {
        await findTitle().trigger('click');
      });

      it('expands the collapse', () => {
        expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(true);
      });
    });

    describe('when `expanded` prop is changed', () => {
      beforeEach(async () => {
        await wrapper.setProps({ expanded: true });
      });

      it('expands the collapse', () => {
        expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(true);
      });
    });
  });

  describe('when collapse is expanded', () => {
    beforeEach(() => {
      mountComponent({ expanded: true });
    });

    it('renders button with `Collapse` text', () => {
      expect(findToggleButton().attributes('aria-label')).toContain('Collapse');
    });

    it('animates chevron', () => {
      // Vue compat doesn't know about component props if it extends other component
      expect(
        findChevronIcon().props('isOn') ?? parseBoolean(findChevronIcon().attributes('is-on')),
      ).toBe(true);
    });

    describe('when `Collapse` button is clicked', () => {
      beforeEach(async () => {
        await findToggleButton().trigger('click');
      });

      it('closes the collapse', () => {
        expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(false);
      });
    });

    describe('when title is clicked', () => {
      beforeEach(async () => {
        await findTitle().trigger('click');
      });

      it('closes the collapse', () => {
        expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(false);
      });
    });
  });
});
