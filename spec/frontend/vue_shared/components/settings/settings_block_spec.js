import { GlCollapse } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

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

  describe('when `defaultExpanded` prop is `false` and URL hash does not match `id`', () => {
    it('renders collapse as closed', () => {
      mountComponent();

      expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(false);
    });
  });

  describe('when `defaultExpanded` prop is `true`', () => {
    it('renders collapse as expanded', () => {
      mountComponent({ defaultExpanded: true });

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

    describe('when `Expand` button is clicked', () => {
      beforeEach(async () => {
        await findToggleButton().trigger('click');
      });

      it('expands the collapse', () => {
        expect(wrapper.findComponent(GlCollapse).props('visible')).toBe(true);
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
  });

  describe('when collapse is expanded', () => {
    beforeEach(() => {
      mountComponent({ defaultExpanded: true });
    });

    it('renders button with `Collapse` text', () => {
      expect(findToggleButton().attributes('aria-label')).toContain('Collapse');
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
