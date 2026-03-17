import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import PageNavigationMenu from '~/vue_shared/components/page_navigation_menu.vue';
import {
  scrollToElement,
  resolveScrollContainer,
  computeActiveSection,
} from '~/lib/utils/scroll_utils';
import { getScrollingElement } from '~/lib/utils/panels';

jest.mock('~/lib/utils/panels');
jest.mock('~/lib/utils/scroll_utils', () => ({
  scrollToElement: jest.fn(),
  resolveScrollContainer: jest.fn(),
  computeActiveSection: jest.fn(),
}));

describe('PageNavigationMenu', () => {
  let wrapper;

  const mockItems = [
    { id: 'section-1', label: 'Section 1' },
    { id: 'section-2', label: 'Section 2' },
    { id: 'section-3', label: 'Section 3' },
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PageNavigationMenu, {
      propsData: {
        items: mockItems,
        ...props,
      },
    });
  };

  const findNav = () => wrapper.find('nav');
  const findTitle = () => wrapper.find('h4');
  const findAllLinks = () => wrapper.findAll('a');
  const findLinkByIndex = (index) => findAllLinks().at(index);

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a nav element', () => {
      expect(findNav().exists()).toBe(true);
    });

    it('renders the default title', () => {
      expect(findTitle().text()).toBe('On this page');
    });

    it('renders all navigation items', () => {
      expect(findAllLinks()).toHaveLength(mockItems.length);
    });

    it('renders correct labels for each item', () => {
      mockItems.forEach((item, index) => {
        expect(findLinkByIndex(index).text()).toBe(item.label);
      });
    });

    it('renders correct href for each item', () => {
      mockItems.forEach((item, index) => {
        expect(findLinkByIndex(index).attributes('href')).toBe(`#${item.id}`);
      });
    });
  });

  describe('custom title prop', () => {
    const customTitle = 'Custom Navigation';

    beforeEach(() => {
      createComponent({ title: customTitle });
    });

    it('renders custom title when provided', () => {
      expect(findTitle().text()).toBe(customTitle);
    });
  });

  describe('custom scrollOffset prop', () => {
    const customOffset = 200;

    beforeEach(() => {
      const mockScrollingElement = {
        scrollTo: jest.fn(),
        scrollTop: 0,
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
      };
      getScrollingElement.mockReturnValue(mockScrollingElement);

      document.getElementById = jest.fn().mockReturnValue({
        getBoundingClientRect: () => ({ top: 500 }),
      });

      createComponent({ scrollOffset: customOffset });
    });

    it('uses custom scroll offset when scrolling', async () => {
      await findLinkByIndex(0).trigger('click');

      expect(scrollToElement).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          offset: customOffset,
          behavior: 'smooth',
        }),
      );
    });
  });

  describe('active state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets first item as active by default', async () => {
      await nextTick();
      const firstLink = findLinkByIndex(0);

      expect(firstLink.classes()).toContain('is-active');
      expect(firstLink.attributes('aria-current')).toBe('location');
    });

    it('does not set other items as active initially', async () => {
      await nextTick();

      expect(findLinkByIndex(1).classes()).not.toContain('is-active');
      expect(findLinkByIndex(1).attributes('aria-current')).toBeUndefined();
    });

    it('updates active state when clicking a different item', async () => {
      const mockScrollingElement = {
        scrollTo: jest.fn(),
        scrollTop: 0,
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
      };
      getScrollingElement.mockReturnValue(mockScrollingElement);

      document.getElementById = jest.fn().mockReturnValue({
        getBoundingClientRect: () => ({ top: 100 }),
      });

      await findLinkByIndex(1).trigger('click');
      await nextTick();

      expect(findLinkByIndex(0).classes()).not.toContain('is-active');
      expect(findLinkByIndex(1).classes()).toContain('is-active');
      expect(findLinkByIndex(1).attributes('aria-current')).toBe('location');
    });
  });

  describe('scrollToSection', () => {
    let mockScrollingElement;
    let mockTarget;

    beforeEach(() => {
      mockScrollingElement = {
        scrollTo: jest.fn(),
        scrollTop: 100,
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
      };
      mockTarget = {
        getBoundingClientRect: () => ({ top: 500 }),
      };

      getScrollingElement.mockReturnValue(mockScrollingElement);
      document.getElementById = jest.fn().mockReturnValue(mockTarget);

      createComponent();
    });

    it('calls getScrollingElement with target element', async () => {
      await findLinkByIndex(0).trigger('click');

      expect(getScrollingElement).toHaveBeenCalledWith(mockTarget);
    });

    it('scrolls to correct position with default offset', async () => {
      await findLinkByIndex(0).trigger('click');

      expect(scrollToElement).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          offset: -10,
          behavior: 'smooth',
        }),
      );
    });

    it('prevents default link behavior', async () => {
      const event = { preventDefault: jest.fn() };
      await findLinkByIndex(0).trigger('click', event);

      expect(event.preventDefault).toHaveBeenCalled();
    });

    it('does not scroll if target element is not found', async () => {
      document.getElementById = jest.fn().mockReturnValue(null);

      await findLinkByIndex(0).trigger('click');

      expect(mockScrollingElement.scrollTo).not.toHaveBeenCalled();
    });

    it('updates active section after scrolling', async () => {
      await findLinkByIndex(1).trigger('click');
      await nextTick();

      expect(wrapper.vm.activeSection).toBe(mockItems[1].id);
    });
  });

  describe('prop validation', () => {
    it('validates items prop structure', () => {
      const { validator } = PageNavigationMenu.props.items;

      expect(validator([{ id: 'test', label: 'Test' }])).toBe(true);
      expect(validator([{ id: 'test' }])).toBe(false);
      expect(validator([{ label: 'Test' }])).toBe(false);
      expect(validator([{}])).toBe(false);
    });
  });

  describe('with empty items', () => {
    beforeEach(() => {
      createComponent({ items: [] });
    });

    it('renders without errors', () => {
      expect(findNav().exists()).toBe(true);
    });

    it('does not set any active section', () => {
      expect(wrapper.vm.activeSection).toBeNull();
    });

    it('does not render any links', () => {
      expect(findAllLinks()).toHaveLength(0);
    });
  });

  describe('scroll tracking', () => {
    let mockScrollingElement;

    beforeEach(() => {
      mockScrollingElement = {
        scrollTo: jest.fn(),
        scrollTop: 0,
        clientHeight: 800,
        scrollHeight: 2000,
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
        getBoundingClientRect: () => ({ top: 0, bottom: 800 }),
      };

      resolveScrollContainer.mockReturnValue(mockScrollingElement);
      getScrollingElement.mockReturnValue(mockScrollingElement);

      document.getElementById = jest.fn((id) => ({
        id,
        getBoundingClientRect: () => ({ top: 100 }),
      }));
    });

    it('initializes scroll tracking on mount', () => {
      createComponent();

      expect(resolveScrollContainer).toHaveBeenCalledWith(mockItems);
      expect(mockScrollingElement.addEventListener).toHaveBeenCalledWith(
        'scroll',
        expect.any(Function),
        { passive: true },
      );
    });

    it('does not initialize scroll tracking if container is not found', () => {
      resolveScrollContainer.mockReturnValue(null);

      createComponent();

      expect(resolveScrollContainer).toHaveBeenCalledWith(mockItems);
      expect(mockScrollingElement.addEventListener).not.toHaveBeenCalled();
    });

    it('calls computeActiveSection on initial load', () => {
      computeActiveSection.mockReturnValue('section-2');

      createComponent();

      expect(computeActiveSection).toHaveBeenCalledWith(mockItems, mockScrollingElement);
    });

    it('updates active section when computeActiveSection returns a different id', async () => {
      computeActiveSection.mockReturnValue('section-2');

      createComponent();
      await nextTick();

      expect(wrapper.vm.activeSection).toBe('section-2');
    });

    it('does not update active section if computeActiveSection returns null', async () => {
      computeActiveSection.mockReturnValue(null);

      createComponent();
      const initialActive = wrapper.vm.activeSection;

      wrapper.vm.handleScroll();
      await nextTick();

      expect(wrapper.vm.activeSection).toBe(initialActive);
    });

    it('does not update active section if computeActiveSection returns the same id', async () => {
      computeActiveSection.mockReturnValue('section-1');

      createComponent();
      await nextTick();

      const setActiveSection = jest.fn();
      wrapper.vm.activeSection = 'section-1';
      wrapper.vm.$watch = setActiveSection;

      wrapper.vm.handleScroll();
      await nextTick();

      expect(wrapper.vm.activeSection).toBe('section-1');
    });

    it('removes scroll listener on destroy', () => {
      createComponent();

      wrapper.destroy();

      expect(mockScrollingElement.removeEventListener).toHaveBeenCalledWith(
        'scroll',
        expect.any(Function),
      );
    });

    it('suppresses auto-update during smooth scroll delay', async () => {
      computeActiveSection.mockReturnValue('section-2');

      createComponent({ autoUpdateDelay: 1000 });

      document.getElementById = jest.fn().mockReturnValue({
        getBoundingClientRect: () => ({ top: 100 }),
      });

      await findLinkByIndex(1).trigger('click');
      await nextTick();

      computeActiveSection.mockReturnValue('section-3');
      wrapper.vm.handleScroll();
      await nextTick();

      expect(wrapper.vm.activeSection).toBe('section-2');
    });
  });
});
