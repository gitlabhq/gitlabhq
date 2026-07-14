import { GlButton, GlIcon, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import { TIERS } from '~/super_sidebar/components/feature_library/constants';

const baseItem = {
  id: 'repository',
  title: 'Repository',
  description: 'Browse and manage your code',
  icon: 'code',
  category: 'code',
  tier: TIERS.FREE,
};

describe('FeatureLibraryItem', () => {
  let wrapper;

  const createWrapper = ({ item = baseItem, pinned = false, solidBackground = false } = {}) => {
    wrapper = mountExtended(FeatureLibraryItem, {
      propsData: { item, pinned, solidBackground },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
    });
  };

  const findTitle = () => wrapper.findByTestId('feature-library-item-title');
  const findTitleLink = () => wrapper.findComponent(GlLink);
  const findDescription = () => wrapper.findByTestId('feature-library-item-description');
  const findTierLabel = () => wrapper.findByTestId('feature-library-item-tier');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findPinButton = () => wrapper.findComponent(GlButton);

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('renders the icon', () => {
      expect(findIcon().props('name')).toBe('code');
    });

    it('renders the title', () => {
      expect(findTitle().text()).toBe('Repository');
    });

    it('renders the description', () => {
      expect(findDescription().text()).toBe('Browse and manage your code');
    });
  });

  describe('tier label', () => {
    it.each([
      [{ tier: TIERS.PREMIUM }, 'Premium'],
      [{ tier: TIERS.ULTIMATE }, 'Ultimate'],
      [{ tier: TIERS.ADD_ON }, 'Add-on'],
    ])('renders %j as "%s"', (tierProps, expected) => {
      createWrapper({ item: { ...baseItem, ...tierProps } });
      expect(findTierLabel().text()).toBe(expected);
    });

    it.each([[{ tier: TIERS.FREE }], [{ tier: undefined }]])(
      'does not render a tier badge for %j',
      (tierProps) => {
        createWrapper({ item: { ...baseItem, ...tierProps } });
        expect(findTierLabel().exists()).toBe(false);
      },
    );
  });

  describe('layout', () => {
    it('top-aligns the icon tile with the heading', () => {
      createWrapper();
      expect(wrapper.classes()).toContain('gl-items-start');
      expect(wrapper.classes()).not.toContain('gl-items-center');
    });
  });

  describe('solidBackground prop', () => {
    it('uses a transparent background with a fill hover by default', () => {
      createWrapper();
      expect(wrapper.classes()).toContain('gl-bg-transparent');
      expect(wrapper.classes()).toContain('hover:gl-bg-strong');
    });

    it('uses a solid background with a shadow hover when solidBackground is true', () => {
      createWrapper({ solidBackground: true });
      expect(wrapper.classes()).toContain('gl-bg-default');
      expect(wrapper.classes()).not.toContain('gl-bg-transparent');
      // On a strong-fill backdrop, a fill hover would blend into it, so the
      // chip elevates with a shadow instead.
      expect(wrapper.classes()).toContain('hover:gl-shadow-md');
      expect(wrapper.classes()).not.toContain('hover:gl-bg-strong');
    });
  });

  describe('title navigation', () => {
    it('renders the title as a plain span (no link) when the item has no link', async () => {
      createWrapper();
      expect(findTitle().element.tagName).toBe('SPAN');
      expect(findTitleLink().exists()).toBe(false);

      await findTitle().trigger('click');
      expect(wrapper.emitted('navigate')).toBeUndefined();
    });

    it('renders the title as a link when the item has a link', () => {
      createWrapper({ item: { ...baseItem, link: '/-/repository' } });
      expect(findTitle().element.tagName).toBe('A');
      expect(findTitleLink().attributes('href')).toBe('/-/repository');
    });

    it('emits navigate with the item id when the title link is clicked', async () => {
      createWrapper({ item: { ...baseItem, link: '/-/repository' } });
      const link = findTitleLink();
      link.element.addEventListener('click', (e) => e.preventDefault());
      await link.trigger('click');
      expect(wrapper.emitted('navigate')).toEqual([['repository']]);
    });
  });

  describe('pin button', () => {
    it('emits pin-toggle with nextState=true and the title when not pinned', async () => {
      createWrapper({ pinned: false });
      await findPinButton().trigger('click');
      expect(wrapper.emitted('pin-toggle')).toEqual([['repository', true, 'Repository']]);
    });

    it('emits pin-toggle with nextState=false and the title when pinned', async () => {
      createWrapper({ pinned: true });
      await findPinButton().trigger('click');
      expect(wrapper.emitted('pin-toggle')).toEqual([['repository', false, 'Repository']]);
    });

    it('uses "Pin" aria-label when not pinned', () => {
      createWrapper({ pinned: false });
      expect(findPinButton().attributes('aria-label')).toBe('Pin Repository');
    });

    it('uses "Unpin" aria-label when pinned', () => {
      createWrapper({ pinned: true });
      expect(findPinButton().attributes('aria-label')).toBe('Unpin Repository');
    });

    it('shows "Pin" tooltip when not pinned', () => {
      createWrapper({ pinned: false });
      expect(getBinding(findPinButton().element, 'gl-tooltip').value).toBe('Pin');
    });

    it('shows "Unpin" tooltip when pinned', () => {
      createWrapper({ pinned: true });
      expect(getBinding(findPinButton().element, 'gl-tooltip').value).toBe('Unpin');
    });
  });
});
