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
  link: '/-/repository',
};

describe('FeatureLibraryItem', () => {
  let wrapper;

  const createWrapper = ({
    item = baseItem,
    pinned = false,
    solidBackground = false,
    supportsPins = true,
  } = {}) => {
    wrapper = mountExtended(FeatureLibraryItem, {
      propsData: { item, pinned, solidBackground, supportsPins },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
      attachTo: document.body,
    });
  };

  const findContent = () => wrapper.findByTestId('feature-library-item-content');
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
      [{ tier: TIERS.FREE }, 'Free'],
      [{ tier: undefined }, 'Free'],
    ])('renders %j as "%s"', (tierProps, expected) => {
      createWrapper({ item: { ...baseItem, ...tierProps } });
      expect(findTierLabel().text()).toBe(expected);
    });
  });

  describe('title navigation', () => {
    it('renders the title as a link', () => {
      createWrapper();
      expect(findTitle().element.tagName).toBe('A');
      expect(findTitleLink().attributes('href')).toBe('/-/repository');
    });

    it('emits navigate with the item id when the title link is clicked', async () => {
      createWrapper();
      const link = findTitleLink();
      link.element.addEventListener('click', (e) => e.preventDefault());
      await link.trigger('click');
      expect(wrapper.emitted('navigate')).toEqual([['repository']]);
    });

    it('stretches the title link over the tile content area', () => {
      createWrapper();
      // The ::after overlay stretches against the positioned content wrapper.
      expect(findContent().classes()).toContain('gl-relative');
      expect(findTitleLink().classes()).toContain('gl-stretched-link');
    });

    it('keeps the pin action outside the stretched link click target', () => {
      createWrapper();
      expect(findContent().findComponent(GlButton).exists()).toBe(false);
    });
  });

  describe('focus()', () => {
    it('moves keyboard focus to the title link when the item has a link', () => {
      createWrapper();

      wrapper.vm.focus();

      expect(document.activeElement).toBe(findTitleLink().element);
    });
  });

  describe('pin button', () => {
    it('is not rendered when pins are not supported', () => {
      createWrapper({ supportsPins: false });
      expect(findPinButton().exists()).toBe(false);
    });

    it('is rendered when pins are supported', () => {
      createWrapper({ supportsPins: true });
      expect(findPinButton().exists()).toBe(true);
    });

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
