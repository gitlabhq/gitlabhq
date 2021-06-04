import { setHTMLFixture } from 'helpers/fixtures';
import { initSidebarTracking } from '~/pages/shared/nav/sidebar_tracking';

describe('~/pages/shared/nav/sidebar_tracking.js', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <aside class="nav-sidebar">
        <div class="nav-sidebar-inner-scroll">
          <ul class="sidebar-top-level-items">
            <li data-track-label="project_information_menu" class="home">
              <a aria-label="Project information" class="shortcuts-project-information has-sub-items" href="">
                  <span class="nav-icon-container">
                    <svg class="s16" data-testid="project-icon">
                        <use xlink:href="/assets/icons-1b2dadc4c3d49797908ba67b8f10da5d63dd15d859bde28d66fb60bbb97a4dd5.svg#project"></use>
                    </svg>
                  </span>
                  <span class="nav-item-name">Project information</span>
              </a>
              <ul class="sidebar-sub-level-items">
                <li class="fly-out-top-item">
                  <a aria-label="Project information" href="#">
                    <strong class="fly-out-top-item-name">Project information</strong>
                  </a>
                </li>
                <li class="divider fly-out-top-item"></li>
                <li data-track-label="activity" class="">
                  <a aria-label="Activity" class="shortcuts-project-activity" href=#">
                    <span>Activity</span>
                  </a>
                </li>
                <li data-track-label="labels" class="">
                  <a aria-label="Labels" href="#">
                    <span>Labels</span>
                  </a>
                </li>
                <li data-track-label="members" class="">
                  <a aria-label="Members" href="#">
                    <span>Members</span>
                  </a>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </aside>
    `);

    initSidebarTracking();
  });

  describe('sidebar is not collapsed', () => {
    describe('menu is not expanded', () => {
      it('sets the proper data tracking attributes when clicking on menu', () => {
        const menu = document.querySelector('li[data-track-label="project_information_menu"]');
        const menuLink = menu.querySelector('a');

        menu.classList.add('is-over', 'is-showing-fly-out');
        menuLink.click();

        expect(menu.dataset).toMatchObject({
          trackAction: 'click_menu',
          trackExtra: JSON.stringify({
            sidebar_display: 'Expanded',
            menu_display: 'Fly out',
          }),
        });
      });

      it('sets the proper data tracking attributes when clicking on submenu', () => {
        const menu = document.querySelector('li[data-track-label="activity"]');
        const menuLink = menu.querySelector('a');
        const submenuList = document.querySelector('ul.sidebar-sub-level-items');

        submenuList.classList.add('fly-out-list');
        menuLink.click();

        expect(menu.dataset).toMatchObject({
          trackAction: 'click_menu_item',
          trackExtra: JSON.stringify({
            sidebar_display: 'Expanded',
            menu_display: 'Fly out',
          }),
        });
      });
    });

    describe('menu is expanded', () => {
      it('sets the proper data tracking attributes when clicking on menu', () => {
        const menu = document.querySelector('li[data-track-label="project_information_menu"]');
        const menuLink = menu.querySelector('a');

        menu.classList.add('active');
        menuLink.click();

        expect(menu.dataset).toMatchObject({
          trackAction: 'click_menu',
          trackExtra: JSON.stringify({
            sidebar_display: 'Expanded',
            menu_display: 'Expanded',
          }),
        });
      });

      it('sets the proper data tracking attributes when clicking on submenu', () => {
        const menu = document.querySelector('li[data-track-label="activity"]');
        const menuLink = menu.querySelector('a');

        menu.classList.add('active');
        menuLink.click();

        expect(menu.dataset).toMatchObject({
          trackAction: 'click_menu_item',
          trackExtra: JSON.stringify({
            sidebar_display: 'Expanded',
            menu_display: 'Expanded',
          }),
        });
      });
    });
  });

  describe('sidebar is collapsed', () => {
    beforeEach(() => {
      document.querySelector('aside.nav-sidebar').classList.add('js-sidebar-collapsed');
    });

    it('sets the proper data tracking attributes when clicking on menu', () => {
      const menu = document.querySelector('li[data-track-label="project_information_menu"]');
      const menuLink = menu.querySelector('a');

      menu.classList.add('is-over', 'is-showing-fly-out');
      menuLink.click();

      expect(menu.dataset).toMatchObject({
        trackAction: 'click_menu',
        trackExtra: JSON.stringify({
          sidebar_display: 'Collapsed',
          menu_display: 'Fly out',
        }),
      });
    });

    it('sets the proper data tracking attributes when clicking on submenu', () => {
      const menu = document.querySelector('li[data-track-label="activity"]');
      const menuLink = menu.querySelector('a');
      const submenuList = document.querySelector('ul.sidebar-sub-level-items');

      submenuList.classList.add('fly-out-list');
      menuLink.click();

      expect(menu.dataset).toMatchObject({
        trackAction: 'click_menu_item',
        trackExtra: JSON.stringify({
          sidebar_display: 'Collapsed',
          menu_display: 'Fly out',
        }),
      });
    });
  });
});
