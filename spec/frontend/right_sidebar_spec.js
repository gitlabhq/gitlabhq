import $ from 'jquery';
import RightSidebar from '~/right_sidebar';
import { getJSONFixture, loadHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/constants';
import axiosMock from 'helpers/axios_mock';
import spyOnEvent from 'helpers/jquery';

describe('RightSidebar', () => {
  const endpointUrl = `${TEST_HOST}/frontend-fixtures/issues-project/todos`;

  let $aside;
  let $page;
  let $icon;
  let $toggle;
  let $labelsIcon;
  let sidebar;

  const expectExpandedSidebar = isExpanded => {
    expect($aside.hasClass('right-sidebar-expanded')).toBe(isExpanded);
    expect($page.hasClass('right-sidebar-expanded')).toBe(isExpanded);
    expect($icon.hasClass('fa-angle-double-right')).toBe(isExpanded);
    expect($aside.hasClass('right-sidebar-collapsed')).toBe(!isExpanded);
    expect($page.hasClass('right-sidebar-collapsed')).toBe(!isExpanded);
    expect($icon.hasClass('fa-angle-double-left')).toBe(!isExpanded);
  };

  beforeEach(() => {
    global.gl = {
      lazyLoader: {
        loadCheck: jest.fn(),
      },
    };
    loadHTMLFixture('issues/open-issue.html.raw');
    $aside = $('.right-sidebar');
    $page = $('.layout-page');
    $icon = $aside.find('i');
    $toggle = $aside.find('.js-sidebar-toggle');
    $labelsIcon = $aside.find('.sidebar-collapsed-icon');
    sidebar = new RightSidebar();
  });

  it('expands/collapses the sidebar when arrow is clicked', () => {
    expectExpandedSidebar(true);
    $toggle.click();
    expectExpandedSidebar(false);
    $toggle.click();
    expectExpandedSidebar(true);
  });

  it('expands when sidebar icons clicked', () => {
    $toggle.click();
    expectExpandedSidebar(false);
    $labelsIcon.click();
    expectExpandedSidebar(true);
  });

  it('broadcasts todo:toggle event when add todo clicked', done => {
    const todos = getJSONFixture('todos/todos.json');
    axiosMock.onPost(endpointUrl).replyOnce(200, todos);
    const todoToggleSpy = spyOnEvent(document, 'todo:toggle');
    todoToggleSpy.mockImplementation(() => done());

    const $toggleTodoButton = $('.issuable-sidebar-header .js-issuable-todo');
    $toggleTodoButton.click();
  });

  it('does not hide collapsed icons', () => {
    const icons = document.querySelectorAll('.sidebar-collapsed-icon');
    expect(icons.length).not.toBe(0);
    icons.forEach(iconElement => {
      expect(iconElement.querySelector('.fa, svg').classList.contains('hidden')).toBe(false);
    });
  });

  describe('sidebarToggleClicked', () => {
    let dummyEvent;

    beforeEach(() => {
      dummyEvent = new Event('dummy');
      $icon.removeClass('fa-angle-double-right');
    });

    it('calls loadCheck if lazyLoader is set', () => {
      sidebar.sidebarToggleClicked(dummyEvent);

      expect(gl.lazyLoader.loadCheck).toHaveBeenCalled();
    });

    it('does not throw if lazyLoader is not defined', () => {
      global.gl.lazyLoader = undefined;

      sidebar.sidebarToggleClicked(dummyEvent);
    });
  });
});
