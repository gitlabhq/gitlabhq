import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';

describe('wikis/utils/sidebar_toggle', () => {
  let sidebar;

  const expectSidebarExpanded = () => {
    expect(sidebar.classList.contains('sidebar-expanded')).toBe(true);
    expect(sidebar.classList.contains('sidebar-collapsed')).toBe(false);
  };

  const expectSidebarCollapsed = () => {
    expect(sidebar.classList.contains('sidebar-collapsed')).toBe(true);
    expect(sidebar.classList.contains('sidebar-expanded')).toBe(false);
  };

  const expectPersistedAs = (value) => {
    expect(localStorage.getItem('wiki-sidebar-open')).toBe(value);
  };

  const setSidebarExpanded = () => {
    sidebar.classList.add('sidebar-expanded');
    sidebar.classList.remove('sidebar-collapsed');
  };

  beforeEach(() => {
    setHTMLFixture('<div class="js-wiki-sidebar sidebar-collapsed"></div>');
    sidebar = document.querySelector('.js-wiki-sidebar');
  });

  afterEach(() => {
    resetHTMLFixture();
    localStorage.clear();
  });

  describe('toggleWikiSidebar', () => {
    it('expands collapsed sidebar and persists', () => {
      toggleWikiSidebar();

      expectSidebarExpanded();
      expectPersistedAs('true');
    });

    it('collapses expanded sidebar and persists', () => {
      setSidebarExpanded();

      toggleWikiSidebar();

      expectSidebarCollapsed();
      expectPersistedAs('false');
    });

    it('can toggle without persisting', () => {
      toggleWikiSidebar(false);

      expectSidebarExpanded();
      expectPersistedAs(null);
    });

    it('can toggle collapse without persisting', () => {
      setSidebarExpanded();

      toggleWikiSidebar(false);

      expectSidebarCollapsed();
      expectPersistedAs(null);
    });

    it('handles missing sidebar gracefully', () => {
      resetHTMLFixture();
      expect(() => toggleWikiSidebar()).not.toThrow();
    });
  });
});
