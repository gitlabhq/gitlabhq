import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import htmlOpenIssues from 'test_fixtures/issues/open-issue.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import Sidebar from '~/right_sidebar';

let $aside = null;
let $toggle = null;
let $toggleContainer = null;
let $expandIcon = null;
let $collapseIcon = null;
let $page = null;
let $labelsIcon = null;

const assertSidebarState = (state) => {
  const shouldBeExpanded = state === 'expanded';
  const shouldBeCollapsed = state === 'collapsed';
  expect($aside.hasClass('right-sidebar-expanded')).toBe(shouldBeExpanded);
  expect($page.hasClass('right-sidebar-expanded')).toBe(shouldBeExpanded);
  expect($toggleContainer.data('is-expanded')).toBe(shouldBeExpanded);
  expect($expandIcon.hasClass('hidden')).toBe(shouldBeExpanded);
  expect($aside.hasClass('right-sidebar-collapsed')).toBe(shouldBeCollapsed);
  expect($page.hasClass('right-sidebar-collapsed')).toBe(shouldBeCollapsed);
  expect($collapseIcon.hasClass('hidden')).toBe(shouldBeCollapsed);
};

describe('RightSidebar', () => {
  describe('fixture tests', () => {
    let mock;

    beforeEach(() => {
      setHTMLFixture(htmlOpenIssues);
      mock = new MockAdapter(axios);
      new Sidebar(); // eslint-disable-line no-new
      $aside = $('.right-sidebar');
      $page = $('.layout-page');
      $toggleContainer = $('.js-sidebar-toggle-container');
      $expandIcon = $aside.find('.js-sidebar-expand');
      $collapseIcon = $aside.find('.js-sidebar-collapse');
      $toggle = $aside.find('.js-sidebar-toggle');
      $labelsIcon = $aside.find('.sidebar-collapsed-icon');
    });

    afterEach(() => {
      mock.restore();

      resetHTMLFixture();
    });

    it('should expand/collapse the sidebar when arrow is clicked', () => {
      assertSidebarState('expanded');
      $toggle.click();
      assertSidebarState('collapsed');
      $toggle.click();
      assertSidebarState('expanded');
    });

    it('should float over the page and when sidebar icons clicked', () => {
      $labelsIcon.click();
      assertSidebarState('expanded');
    });

    it('should collapse when the icon arrow clicked while it is floating on page', () => {
      $labelsIcon.click();
      assertSidebarState('expanded');
      $toggle.click();
      assertSidebarState('collapsed');
    });

    it('should not hide collapsed icons', () => {
      $toggle.click();
      assertSidebarState('collapsed');

      [].forEach.call(document.querySelectorAll('.sidebar-collapsed-icon'), (el) => {
        expect(el.querySelector('.fa, svg').classList.contains('hidden')).toBe(false);
      });
    });
  });
});
