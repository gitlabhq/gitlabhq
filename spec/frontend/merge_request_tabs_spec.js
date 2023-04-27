import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import htmlMergeRequestsWithTaskList from 'test_fixtures/merge_requests/merge_request_with_task_list.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initMrPage from 'helpers/init_vue_mr_page_helper';
import { stubPerformanceWebAPI } from 'helpers/performance';
import axios from '~/lib/utils/axios_utils';
import MergeRequestTabs from '~/merge_request_tabs';
import Diff from '~/diff';
import '~/lib/utils/common_utils';
import '~/lib/utils/url_utility';

jest.mock('~/lib/utils/webpack', () => ({
  resetServiceWorkersPublicPath: jest.fn(),
}));

describe('MergeRequestTabs', () => {
  const testContext = {};
  const stubLocation = {};
  const setLocation = (stubs) => {
    const defaults = {
      pathname: '',
      search: '',
      hash: '',
    };
    $.extend(stubLocation, defaults, stubs || {});
  };

  beforeEach(() => {
    stubPerformanceWebAPI();

    initMrPage();

    testContext.class = new MergeRequestTabs({ stubLocation });
    setLocation();

    testContext.spies = {
      history: jest.spyOn(window.history, 'pushState').mockImplementation(() => {}),
    };

    gl.mrWidget = {};
  });

  describe('clickTab', () => {
    let params;

    beforeEach(() => {
      document.documentElement.scrollTop = 100;

      params = {
        metaKey: false,
        ctrlKey: false,
        which: 1,
        stopImmediatePropagation() {},
        preventDefault() {},
        currentTarget: {
          getAttribute(attr) {
            return attr === 'href' ? 'a/tab/url' : null;
          },
        },
      };
    });

    it("stores the current scroll position if there's an active tab", () => {
      testContext.class.currentTab = 'someTab';

      testContext.class.clickTab(params);

      expect(testContext.class.scrollPositions.someTab).toBe(100);
    });

    it("doesn't store a scroll position if there's no active tab", () => {
      // this happens on first load, and we just don't want to store empty values in the `null` property
      testContext.class.currentTab = null;

      testContext.class.clickTab(params);

      expect(testContext.class.scrollPositions).toEqual({});
    });
  });

  describe('opensInNewTab', () => {
    const windowTarget = '_blank';
    let clickTabParams;
    let tabUrl;

    beforeEach(() => {
      setHTMLFixture(htmlMergeRequestsWithTaskList);

      tabUrl = $('.commits-tab a').attr('href');

      clickTabParams = {
        metaKey: false,
        ctrlKey: false,
        which: 1,
        stopImmediatePropagation() {},
        preventDefault() {},
        currentTarget: {
          getAttribute(attr) {
            return attr === 'href' ? tabUrl : null;
          },
        },
      };
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    describe('meta click', () => {
      let metakeyEvent;

      beforeEach(() => {
        metakeyEvent = $.Event('click', { keyCode: 91, ctrlKey: true });
      });

      it('opens page when commits link is clicked', () => {
        jest.spyOn(window, 'open').mockImplementation((url, name) => {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        testContext.class.bindEvents();
        $('.merge-request-tabs .commits-tab a').trigger(metakeyEvent);

        expect(window.open).toHaveBeenCalled();
      });

      it('opens page when commits badge is clicked', () => {
        jest.spyOn(window, 'open').mockImplementation((url, name) => {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        testContext.class.bindEvents();
        $('.merge-request-tabs .commits-tab a .badge').trigger(metakeyEvent);

        expect(window.open).toHaveBeenCalled();
      });
    });

    it('opens page tab in a new browser tab with Ctrl+Click - Windows/Linux', () => {
      jest.spyOn(window, 'open').mockImplementation((url, name) => {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      testContext.class.clickTab({ ...clickTabParams, metaKey: true });

      expect(window.open).toHaveBeenCalled();
    });

    it('opens page tab in a new browser tab with Cmd+Click - Mac', () => {
      jest.spyOn(window, 'open').mockImplementation((url, name) => {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      testContext.class.clickTab({ ...clickTabParams, ctrlKey: true });

      expect(window.open).toHaveBeenCalled();
    });

    it('opens page tab in a new browser tab with Middle-click - Mac/PC', () => {
      jest.spyOn(window, 'open').mockImplementation((url, name) => {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      testContext.class.clickTab({ ...clickTabParams, which: 2 });

      expect(window.open).toHaveBeenCalled();
    });
  });

  describe('setCurrentAction', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onAny().reply({ data: {} });
      testContext.subject = testContext.class.setCurrentAction;
    });

    afterEach(() => {
      mock.restore();
      window.history.replaceState({}, '', '/');
    });

    it('changes from commits', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/commits',
      });

      expect(testContext.subject('show')).toBe('/foo/bar/-/merge_requests/1');
      expect(testContext.subject('diffs')).toBe('/foo/bar/-/merge_requests/1/diffs');
    });

    it('changes from diffs', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/diffs',
      });

      expect(testContext.subject('show')).toBe('/foo/bar/-/merge_requests/1');
      expect(testContext.subject('commits')).toBe('/foo/bar/-/merge_requests/1/commits');
    });

    it('changes from diffs.html', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/diffs.html',
      });

      expect(testContext.subject('show')).toBe('/foo/bar/-/merge_requests/1');
      expect(testContext.subject('commits')).toBe('/foo/bar/-/merge_requests/1/commits');
    });

    it('changes from notes', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1',
      });

      expect(testContext.subject('diffs')).toBe('/foo/bar/-/merge_requests/1/diffs');
      expect(testContext.subject('commits')).toBe('/foo/bar/-/merge_requests/1/commits');
    });

    it('includes search parameters and hash string', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/diffs',
        search: '?view=parallel',
        hash: '#L15-35',
      });

      expect(testContext.subject('show')).toBe('/foo/bar/-/merge_requests/1?view=parallel#L15-35');
    });

    it('replaces the current history state', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1',
      });
      window.history.replaceState(
        {
          url: window.location.href,
          action: 'show',
        },
        document.title,
        window.location.href,
      );

      const newState = testContext.subject('commits');

      expect(testContext.spies.history).toHaveBeenCalledWith(
        {
          url: newState,
          action: 'commits',
        },
        document.title,
        newState,
      );
    });

    it('treats "show" like "notes"', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/commits',
      });

      expect(testContext.subject('show')).toBe('/foo/bar/-/merge_requests/1');
    });
  });

  describe('expandViewContainer', () => {
    beforeEach(() => {
      $('body').append(
        '<div class="content-wrapper"><div class="container-fluid container-limited"></div></div>',
      );
    });

    afterEach(() => {
      $('.content-wrapper').remove();
    });

    it('removes container-limited from containers', () => {
      testContext.class.expandViewContainer();

      expect($('.content-wrapper .container-limited')).toHaveLength(0);
    });

    it('does not add container-limited when fluid layout is prefered', () => {
      $('.content-wrapper .container-fluid').removeClass('container-limited');

      testContext.class.expandViewContainer(false);

      expect($('.content-wrapper .container-limited')).toHaveLength(0);
    });

    it('does remove container-limited from breadcrumbs', () => {
      $('.container-limited').addClass('breadcrumbs');
      testContext.class.expandViewContainer();

      expect($('.content-wrapper .container-limited')).toHaveLength(1);
    });
  });

  describe('tabShown', () => {
    const mainContent = document.createElement('div');
    const tabContent = document.createElement('div');

    beforeEach(() => {
      $.fn.renderGFM = jest.fn();
      jest.spyOn(mainContent, 'getBoundingClientRect').mockReturnValue({ top: 10 });
      jest.spyOn(tabContent, 'getBoundingClientRect').mockReturnValue({ top: 100 });
      jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
      jest.spyOn(document, 'querySelector').mockImplementation((selector) => {
        return selector === '.content-wrapper' ? mainContent : tabContent;
      });
      testContext.class.currentAction = 'commits';
    });

    it('calls window scrollTo with options if document has scrollBehavior', () => {
      document.documentElement.style.scrollBehavior = '';

      testContext.class.tabShown('commits', 'foobar');

      expect(window.scrollTo.mock.calls[0][0]).toEqual({ top: 39, behavior: 'smooth' });
    });

    it('calls window scrollTo with two args if document does not have scrollBehavior', () => {
      jest.spyOn(document.documentElement, 'style', 'get').mockReturnValue({});

      testContext.class.tabShown('commits', 'foobar');

      expect(window.scrollTo.mock.calls[0]).toEqual([0, 39]);
    });

    it.each`
      tab          | hides    | hidesText
      ${'show'}    | ${false} | ${'shows'}
      ${'diffs'}   | ${true}  | ${'hides'}
      ${'commits'} | ${true}  | ${'hides'}
    `('$hidesText expand button on $tab tab', ({ tab, hides }) => {
      window.gon = { features: { movedMrSidebar: true } };

      const expandButton = document.createElement('div');
      expandButton.classList.add('js-expand-sidebar');

      const tabsContainer = document.createElement('div');
      tabsContainer.innerHTML =
        '<div class="tab-content"><div id="diff-notes-app"></div><div class="commits tab-pane"></div></div>';
      tabsContainer.classList.add('merge-request-tabs-container');
      tabsContainer.appendChild(expandButton);
      document.body.appendChild(tabsContainer);

      testContext.class = new MergeRequestTabs({ stubLocation });
      testContext.class.tabShown(tab, 'foobar');

      testContext.class.expandSidebar.forEach((el) => {
        expect(el.classList.contains('gl-display-none!')).toBe(hides);
      });
    });

    describe('when switching tabs', () => {
      const SCROLL_TOP = 100;

      beforeEach(() => {
        jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
        testContext.class.mergeRequestTabs = document.createElement('div');
        testContext.class.mergeRequestTabPanes = document.createElement('div');
        testContext.class.currentTab = 'tab';
        testContext.class.scrollPositions = { newTab: SCROLL_TOP };
      });

      it('scrolls to the stored position, if one is stored', () => {
        testContext.class.tabShown('newTab');

        jest.advanceTimersByTime(250);

        expect(window.scrollTo.mock.calls[0][0]).toEqual({
          top: SCROLL_TOP,
          left: 0,
          behavior: 'auto',
        });
      });

      it('scrolls to 0, if no position is stored', () => {
        testContext.class.tabShown('unknownTab');

        jest.advanceTimersByTime(250);

        expect(window.scrollTo.mock.calls[0][0]).toEqual({ top: 0, left: 0, behavior: 'auto' });
      });
    });
  });

  describe('tabs <-> diff interactions', () => {
    beforeEach(() => {
      jest.spyOn(testContext.class, 'loadDiff').mockImplementation(() => {});
    });

    describe('switchViewType', () => {
      it('marks the class as having not loaded diffs already', () => {
        testContext.class.diffsLoaded = true;

        testContext.class.switchViewType({});

        expect(testContext.class.diffsLoaded).toBe(false);
      });

      it('reloads the diffs', () => {
        testContext.class.switchViewType({ source: 'a new url' });

        expect(testContext.class.loadDiff).toHaveBeenCalledWith({
          endpoint: 'a new url',
          strip: false,
        });
      });
    });

    describe('createDiff', () => {
      it("creates a Diff if there isn't one", () => {
        expect(testContext.class.diffsClass).toBe(null);

        testContext.class.createDiff();

        expect(testContext.class.diffsClass).toBeInstanceOf(Diff);
      });

      it("doesn't create a Diff if one already exists", () => {
        testContext.class.diffsClass = 'truthy';

        testContext.class.createDiff();

        expect(testContext.class.diffsClass).toBe('truthy');
      });

      it('sets the available MR Tabs event hub to the new Diff', () => {
        expect(testContext.class.diffsClass).toBe(null);

        testContext.class.createDiff();

        expect(testContext.class.diffsClass.mrHub).toBe(testContext.class.eventHub);
      });
    });

    describe('setHubToDiff', () => {
      it('sets the MR Tabs event hub to the child Diff', () => {
        testContext.class.diffsClass = {};

        testContext.class.setHubToDiff();

        expect(testContext.class.diffsClass.mrHub).toBe(testContext.class.eventHub);
      });

      it('does not fatal if theres no child Diff', () => {
        testContext.class.diffsClass = null;

        expect(() => {
          testContext.class.setHubToDiff();
        }).not.toThrow();
      });
    });
  });
});
