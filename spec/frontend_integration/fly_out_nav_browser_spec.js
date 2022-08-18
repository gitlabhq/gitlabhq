import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { SIDEBAR_COLLAPSED_CLASS } from '~/contextual_sidebar';
import {
  calculateTop,
  showSubLevelItems,
  canShowSubItems,
  canShowActiveSubItems,
  mouseEnterTopItems,
  mouseLeaveTopItem,
  getOpenMenu,
  setOpenMenu,
  mousePos,
  getHideSubItemsInterval,
  documentMouseMove,
  getHeaderHeight,
  setSidebar,
  subItemsMouseLeave,
} from '~/fly_out_nav';

describe('Fly out sidebar navigation', () => {
  let el;
  let breakpointSize = 'lg';

  const OLD_SIDEBAR_WIDTH = 200;
  const CONTAINER_INITIAL_BOUNDING_RECT = {
    x: 8,
    y: 8,
    width: 769,
    height: 0,
    top: 8,
    right: 777,
    bottom: 8,
    left: 8,
  };
  const SUB_ITEMS_INITIAL_BOUNDING_RECT = {
    x: 148,
    y: 8,
    width: 0,
    height: 150,
    top: 8,
    right: 148,
    bottom: 158,
    left: 148,
  };
  const mockBoundingClientRect = (elem, rect) => {
    jest.spyOn(elem, 'getBoundingClientRect').mockReturnValue(rect);
  };

  const findSubItems = () => document.querySelector('.sidebar-sub-level-items');
  const mockBoundingRects = () => {
    const subItems = findSubItems();
    mockBoundingClientRect(el, CONTAINER_INITIAL_BOUNDING_RECT);
    mockBoundingClientRect(subItems, SUB_ITEMS_INITIAL_BOUNDING_RECT);
  };
  const mockSidebarFragment = (styleProps = '') =>
    `<div class="sidebar-sub-level-items" style="${styleProps}"></div>`;

  beforeEach(() => {
    el = document.createElement('div');
    el.style.position = 'relative';
    document.body.appendChild(el);

    jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockImplementation(() => breakpointSize);
  });

  afterEach(() => {
    document.body.innerHTML = '';
    breakpointSize = 'lg';
    mousePos.length = 0;

    setSidebar(null);
  });

  describe('calculateTop', () => {
    it('returns boundingRect top', () => {
      const boundingRect = {
        top: 100,
        height: 100,
      };

      expect(calculateTop(boundingRect, 100)).toBe(100);
    });
  });

  describe('getHideSubItemsInterval', () => {
    beforeEach(() => {
      el.innerHTML = mockSidebarFragment('position: fixed; top: 0; left: 100px; height: 150px;');
      mockBoundingRects();
    });

    it('returns 0 if currentOpenMenu is nil', () => {
      setOpenMenu(null);
      expect(getHideSubItemsInterval()).toBe(0);
    });

    it('returns 0 if mousePos is empty', () => {
      expect(getHideSubItemsInterval()).toBe(0);
    });

    it('returns 0 when mouse above sub-items', () => {
      showSubLevelItems(el);
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top - 50,
      });

      expect(getHideSubItemsInterval()).toBe(0);
    });

    it('returns 0 when mouse is below sub-items', () => {
      const subItems = findSubItems();

      showSubLevelItems(el);
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top - subItems.getBoundingClientRect().height + 50,
      });

      expect(getHideSubItemsInterval()).toBe(0);
    });

    it('returns 300 when mouse is moved towards sub-items', () => {
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });

      showSubLevelItems(el);
      documentMouseMove({
        clientX: el.getBoundingClientRect().left + 20,
        clientY: el.getBoundingClientRect().top + 10,
      });

      expect(getHideSubItemsInterval()).toBe(300);
    });
  });

  describe('mouseLeaveTopItem', () => {
    beforeEach(() => {
      jest.spyOn(el.classList, 'remove');
    });

    it('removes is-over class if currentOpenMenu is null', () => {
      setOpenMenu(null);

      mouseLeaveTopItem(el);

      expect(el.classList.remove).toHaveBeenCalledWith('is-over');
    });

    it('removes is-over class if currentOpenMenu is null & there are sub-items', () => {
      setOpenMenu(null);
      el.innerHTML = mockSidebarFragment('position: absolute');

      mouseLeaveTopItem(el);

      expect(el.classList.remove).toHaveBeenCalledWith('is-over');
    });

    it('does not remove is-over class if currentOpenMenu is the passed in sub-items', () => {
      setOpenMenu(null);
      el.innerHTML = mockSidebarFragment('position: absolute');

      setOpenMenu(findSubItems());
      mouseLeaveTopItem(el);

      expect(el.classList.remove).not.toHaveBeenCalled();
    });
  });

  describe('mouseEnterTopItems', () => {
    beforeEach(() => {
      el.innerHTML = mockSidebarFragment(
        `position: absolute; top: 0; left: 100px; height: ${OLD_SIDEBAR_WIDTH}px;`,
      );
      mockBoundingRects();
    });

    it('shows sub-items after 0ms if no menu is open', () => {
      const subItems = findSubItems();
      mouseEnterTopItems(el);

      expect(getHideSubItemsInterval()).toBe(0);

      return new Promise((resolve) => {
        setTimeout(() => {
          expect(subItems.style.display).toBe('block');
          resolve();
        });
      });
    });

    it('shows sub-items after 300ms if a menu is currently open', () => {
      const subItems = findSubItems();

      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });

      setOpenMenu(subItems);

      documentMouseMove({
        clientX: el.getBoundingClientRect().left + 20,
        clientY: el.getBoundingClientRect().top + 10,
      });

      mouseEnterTopItems(el, 0);

      return new Promise((resolve) => {
        setTimeout(() => {
          expect(subItems.style.display).toBe('block');
          resolve();
        });
      });
    });
  });

  describe('showSubLevelItems', () => {
    beforeEach(() => {
      el.innerHTML = mockSidebarFragment('position: absolute');
    });

    it('adds is-over class to el', () => {
      jest.spyOn(el.classList, 'add');

      showSubLevelItems(el);

      expect(el.classList.add).toHaveBeenCalledWith('is-over');
    });

    it('does not show sub-items on mobile', () => {
      breakpointSize = 'xs';

      showSubLevelItems(el);

      expect(findSubItems().style.display).not.toBe('block');
    });

    it('shows sub-items', () => {
      showSubLevelItems(el);

      expect(findSubItems().style.display).toBe('block');
    });

    it('shows collapsed only sub-items if icon only sidebar', () => {
      const subItems = findSubItems();
      const sidebar = document.createElement('div');
      sidebar.classList.add(SIDEBAR_COLLAPSED_CLASS);
      subItems.classList.add('is-fly-out-only');

      setSidebar(sidebar);

      showSubLevelItems(el);

      expect(findSubItems().style.display).toBe('block');
    });

    it('does not show collapsed only sub-items if icon only sidebar', () => {
      const subItems = findSubItems();
      subItems.classList.add('is-fly-out-only');

      showSubLevelItems(el);

      expect(subItems.style.display).not.toBe('block');
    });

    it('sets transform of sub-items', () => {
      const sidebar = document.createElement('div');
      const subItems = findSubItems();

      sidebar.style.width = `${OLD_SIDEBAR_WIDTH}px`;

      document.body.appendChild(sidebar);

      setSidebar(sidebar);
      showSubLevelItems(el);

      expect(subItems.style.transform).toBe(
        `translate3d(${OLD_SIDEBAR_WIDTH}px, ${
          Math.floor(el.getBoundingClientRect().top) - getHeaderHeight()
        }px, 0)`,
      );
    });

    it('sets is-above when element is above', () => {
      const subItems = findSubItems();
      mockBoundingRects();

      subItems.style.height = `${window.innerHeight + el.offsetHeight}px`;
      el.style.top = `${window.innerHeight - el.offsetHeight}px`;

      jest.spyOn(subItems.classList, 'add');

      showSubLevelItems(el);

      expect(subItems.classList.add).toHaveBeenCalledWith('is-above');
    });
  });

  describe('canShowSubItems', () => {
    it('returns true if on desktop size', () => {
      expect(canShowSubItems()).toBe(true);
    });

    it('returns false if on mobile size', () => {
      breakpointSize = 'xs';

      expect(canShowSubItems()).toBe(false);
    });
  });

  describe('canShowActiveSubItems', () => {
    it('returns true by default', () => {
      expect(canShowActiveSubItems(el)).toBe(true);
    });

    it('returns false when active & expanded sidebar', () => {
      const sidebar = document.createElement('div');
      el.classList.add('active');

      setSidebar(sidebar);

      expect(canShowActiveSubItems(el)).toBe(false);
    });

    it('returns true when active & collapsed sidebar', () => {
      const sidebar = document.createElement('div');
      sidebar.classList.add(SIDEBAR_COLLAPSED_CLASS);
      el.classList.add('active');

      setSidebar(sidebar);

      expect(canShowActiveSubItems(el)).toBe(true);
    });
  });

  describe('subItemsMouseLeave', () => {
    beforeEach(() => {
      el.innerHTML = mockSidebarFragment('position: absolute');

      setOpenMenu(findSubItems());
    });

    it('hides subMenu if element is not hovered', () => {
      subItemsMouseLeave(el);

      expect(getOpenMenu()).toBeNull();
    });

    it('does not hide subMenu if element is hovered', () => {
      el.classList.add('is-over');
      subItemsMouseLeave(el);

      expect(getOpenMenu()).not.toBeNull();
    });
  });
});
