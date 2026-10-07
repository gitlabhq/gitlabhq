import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';

describe('wikis/utils/sidebar_toggle', () => {
  let sidebar;
  let overview;

  const getSidebarWidthVar = () => overview.style.getPropertyValue('--wiki-sidebar-width');

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
    setHTMLFixture(
      '<div class="js-wiki-overview"><div class="js-wiki-sidebar sidebar-collapsed"></div></div>',
    );
    sidebar = document.querySelector('.js-wiki-sidebar');
    overview = document.querySelector('.js-wiki-overview');
  });

  afterEach(() => {
    resetHTMLFixture();
    localStorage.clear();
  });

  describe('toggleWikiSidebar', () => {
    describe('when the sidebar is collapsed', () => {
      describe('when toggled', () => {
        beforeEach(() => {
          toggleWikiSidebar();
        });

        it('expands the sidebar', () => {
          expectSidebarExpanded();
        });

        it('persists the open state', () => {
          expectPersistedAs('true');
        });

        it('restores the width variable to the default width', () => {
          expect(getSidebarWidthVar()).toBe('220px');
        });
      });

      describe('when toggled with a stored width', () => {
        beforeEach(() => {
          localStorage.setItem('wiki_sidebar_width', '350');
          toggleWikiSidebar();
        });

        it('restores the width variable to the stored width', () => {
          expect(getSidebarWidthVar()).toBe('350px');
        });
      });

      describe('when toggled without persisting', () => {
        beforeEach(() => {
          toggleWikiSidebar(false);
        });

        it('expands the sidebar', () => {
          expectSidebarExpanded();
        });

        it('does not persist the open state', () => {
          expectPersistedAs(null);
        });
      });
    });

    describe('when the sidebar is expanded', () => {
      beforeEach(() => {
        setSidebarExpanded();
      });

      describe('when toggled', () => {
        beforeEach(() => {
          toggleWikiSidebar();
        });

        it('collapses the sidebar', () => {
          expectSidebarCollapsed();
        });

        it('persists the closed state', () => {
          expectPersistedAs('false');
        });

        it('sets the width variable to 0px', () => {
          expect(getSidebarWidthVar()).toBe('0px');
        });
      });

      describe('when toggled without persisting', () => {
        beforeEach(() => {
          toggleWikiSidebar(false);
        });

        it('collapses the sidebar', () => {
          expectSidebarCollapsed();
        });

        it('does not persist the closed state', () => {
          expectPersistedAs(null);
        });
      });
    });

    describe('when the sidebar is missing', () => {
      beforeEach(() => {
        resetHTMLFixture();
      });

      it('does not throw', () => {
        expect(() => toggleWikiSidebar()).not.toThrow();
      });
    });
  });
});
