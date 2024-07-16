import { GlCollapse } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('Settings Block', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = mountExtended(SettingsBlock, {
      propsData,
      slots: {
        title: '<div data-testid="title-slot">Advanced</div>',
        description: '<div data-testid="description-slot"></div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findTitleSlot = () => wrapper.findByTestId('title-slot');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');
  const findExpandButton = () => wrapper.findByRole('button', { name: 'Expand Advanced' });
  const findCollapseButton = () => wrapper.findByRole('button', { name: 'Collapse Advanced' });
  const findTitle = () => wrapper.findByRole('button', { name: 'Advanced' });

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

  describe('when largeTitle prop is `true`', () => {
    beforeEach(() => {
      mountComponent({ largeTitle: true });
    });

    it('renders title as h2 with the gl-heading-2 css class', () => {
      expect(wrapper.find('h2').exists()).toBe(true);
      expect(wrapper.find('h2').classes()).toContain('gl-heading-2');
    });
  });

  describe('when largeTitle prop is `false`', () => {
    beforeEach(() => {
      mountComponent({ largeTitle: false });
    });

    it('renders title as h4 without the gl-heading-2 class', () => {
      expect(wrapper.find('h4').exists()).toBe(true);
      expect(wrapper.find('h4').classes()).not.toContain('gl-heading-2');
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
      expect(findExpandButton().exists()).toBe(true);
    });

    describe('when `Expand` button is clicked', () => {
      beforeEach(async () => {
        await findExpandButton().trigger('click');
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
      expect(findCollapseButton().exists()).toBe(true);
    });

    describe('when `Collapse` button is clicked', () => {
      beforeEach(async () => {
        await findCollapseButton().trigger('click');
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
