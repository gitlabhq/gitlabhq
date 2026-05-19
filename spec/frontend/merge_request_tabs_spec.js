import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import htmlMergeRequestsWithTaskList from 'test_fixtures/merge_requests/merge_request_with_task_list.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initMrPage from 'helpers/init_vue_mr_page_helper';
import { stubPerformanceWebAPI } from 'helpers/performance';
import setWindowLocation from 'helpers/set_window_location_helper';
import { scrollTo } from '~/lib/utils/scroll_utils';
import axios from '~/lib/utils/axios_utils';
import MergeRequestTabs, { getActionFromHref, pageBundles } from '~/merge_request_tabs';
import * as domUtils from '~/lib/utils/dom_utils';
import Diff from '~/diff';
import { visitUrl } from '~/lib/utils/url_utility';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/constants';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import InternalEvents from '~/tracking/internal_events';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

jest.mock('~/lib/utils/webpack', () => ({
  resetServiceWorkersPublicPath: jest.fn(),
}));

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/lib/utils/scroll_utils', () => ({
  ...jest.requireActual('~/lib/utils/scroll_utils'),
  scrollTo: jest.fn(),
  scrollToElement: jest.fn(),
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

  afterEach(() => {
    resetHTMLFixture();
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

        expect(visitUrl).toHaveBeenCalledWith(expect.any(String), true);
      });

      it('opens page when commits badge is clicked', () => {
        jest.spyOn(window, 'open').mockImplementation((url, name) => {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        testContext.class.bindEvents();
        $('.merge-request-tabs .commits-tab a .badge').trigger(metakeyEvent);

        expect(visitUrl).toHaveBeenCalledWith(expect.any(String), true);
      });
    });

    it('opens page tab in a new browser tab with Ctrl+Click - Windows/Linux', () => {
      jest.spyOn(window, 'open').mockImplementation((url, name) => {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      testContext.class.clickTab({ ...clickTabParams, metaKey: true });

      expect(visitUrl).toHaveBeenCalledWith(expect.any(String), true);
    });

    it('opens page tab in a new browser tab with Cmd+Click - Mac', () => {
      jest.spyOn(window, 'open').mockImplementation((url, name) => {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      testContext.class.clickTab({ ...clickTabParams, ctrlKey: true });

      expect(visitUrl).toHaveBeenCalledWith(expect.any(String), true);
    });

    it('opens page tab in a new browser tab with Middle-click - Mac/PC', () => {
      jest.spyOn(window, 'open').mockImplementation((url, name) => {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      testContext.class.clickTab({ ...clickTabParams, which: 2 });

      expect(visitUrl).toHaveBeenCalledWith(expect.any(String), true);
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

    it('changes from notes ending with a trailing slash', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/',
      });

      expect(testContext.subject('diffs')).toBe('/foo/bar/-/merge_requests/1/diffs');
      expect(testContext.subject('commits')).toBe('/foo/bar/-/merge_requests/1/commits');
    });

    it('changes from diffs ending with a trailing slash', () => {
      setLocation({
        pathname: '/foo/bar/-/merge_requests/1/diffs/',
      });

      expect(testContext.subject('show')).toBe('/foo/bar/-/merge_requests/1');
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

    it.each`
      pathname                                                | action       | expected
      ${'/group/reports/project/-/merge_requests/1'}          | ${'show'}    | ${'/group/reports/project/-/merge_requests/1'}
      ${'/group/reports/project/-/merge_requests/1'}          | ${'reports'} | ${'/group/reports/project/-/merge_requests/1/reports'}
      ${'/group/reports/project/-/merge_requests/1/reports'}  | ${'reports'} | ${'/group/reports/project/-/merge_requests/1/reports'}
      ${'/group/reports/project/-/merge_requests/1/reports'}  | ${'show'}    | ${'/group/reports/project/-/merge_requests/1'}
      ${'/group/project/-/merge_requests/1/diffs'}            | ${'commits'} | ${'/group/project/-/merge_requests/1/commits'}
      ${'/group/project/-/merge_requests/1/commits'}          | ${'diffs'}   | ${'/group/project/-/merge_requests/1/diffs'}
      ${'/group/project/-/merge_requests/1/reports/security'} | ${'show'}    | ${'/group/project/-/merge_requests/1'}
      ${'/group/project/-/merge_requests/1/reports/security'} | ${'reports'} | ${'/group/project/-/merge_requests/1/reports/security'}
      ${'/group/project/-/merge_requests/1/commits'}          | ${'commits'} | ${'/group/project/-/merge_requests/1/commits'}
      ${'/group/project/-/merge_requests/1/diffs/'}           | ${'show'}    | ${'/group/project/-/merge_requests/1'}
      ${'/group/project/-/merge_requests/1/commits.html'}     | ${'show'}    | ${'/group/project/-/merge_requests/1'}
    `(
      'updates URL to $expected if current URL is $pathname and new action is $action',
      ({ pathname, action, expected }) => {
        setLocation({
          pathname,
        });

        expect(testContext.subject(action)).toBe(expected);
      },
    );
  });

  describe('expandViewContainer', () => {
    beforeEach(() => {
      $('.content-wrapper .container-fluid').addClass('container-limited');
    });

    it('removes `container-limited` class from content container', () => {
      expect($('.content-wrapper .container-limited')).toHaveLength(1);
      testContext.class.expandViewContainer();
      expect($('.content-wrapper .container-limited')).toHaveLength(0);
    });

    it('adds the diff-specific width-limiter', () => {
      testContext.class.expandViewContainer();

      expect(testContext.class.contentWrapper.classList.contains('diffs-container-limited')).toBe(
        true,
      );
    });
  });

  describe('resetViewContainer', () => {
    it('does not add `container-limited` CSS class when fluid layout is preferred', () => {
      testContext.class.resetViewContainer();

      expect($('.content-wrapper .container-limited')).toHaveLength(0);
    });

    it('adds `container-limited` CSS class back when fixed layout is preferred', () => {
      document.body.innerHTML = '';
      initMrPage();
      $('.content-wrapper .container-fluid').addClass('container-limited');
      // recreate the instance so that `isFixedLayoutPreferred` is re-evaluated
      testContext.class = new MergeRequestTabs({ stubLocation });
      $('.content-wrapper .container-fluid').removeClass('container-limited');

      testContext.class.resetViewContainer();

      expect($('.content-wrapper .container-limited')).toHaveLength(1);
    });

    it('removes the diff-specific width-limiter', () => {
      testContext.class.resetViewContainer();

      expect(testContext.class.contentWrapper.classList.contains('diffs-container-limited')).toBe(
        false,
      );
    });
  });

  describe('tabShown', () => {
    const mainContent = document.createElement('div');
    const tabContent = document.createElement('div');

    beforeEach(() => {
      $.fn.renderGFM = jest.fn();
      jest.spyOn(mainContent, 'getBoundingClientRect').mockReturnValue({ top: 10 });
      jest.spyOn(tabContent, 'getBoundingClientRect').mockReturnValue({ top: 100 });
      jest.spyOn(document, 'querySelector').mockImplementation((selector) => {
        return selector === '.content-wrapper' ? mainContent : tabContent;
      });
      testContext.class.currentAction = 'commits';
    });

    it('calls scrollTo', () => {
      jest.spyOn(document.documentElement, 'style', 'get').mockReturnValue({});

      testContext.class.tabShown('commits', 'foobar');

      expect(scrollTo.mock.calls[0]).toEqual([{ top: 39, behavior: 'smooth' }]);
    });

    it.each`
      tab          | hides    | hidesText
      ${'show'}    | ${false} | ${'shows'}
      ${'diffs'}   | ${true}  | ${'hides'}
      ${'commits'} | ${true}  | ${'hides'}
    `('$hidesText expand button on $tab tab', ({ tab, hides }) => {
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
        expect(el.classList.contains('!gl-hidden')).toBe(hides);
      });
    });

    it.each`
      tab          | hidden
      ${'show'}    | ${true}
      ${'diffs'}   | ${false}
      ${'commits'} | ${true}
    `('rapid diffs toggle hidden=$hidden on $tab tab', ({ tab, hidden }) => {
      const toggle = document.createElement('div');
      toggle.id = 'js-rapid-diffs-toggle';
      document.body.appendChild(toggle);

      testContext.class = new MergeRequestTabs({ stubLocation });
      testContext.class.tabShown(tab, 'foobar');

      expect(toggle.classList.contains('!gl-hidden')).toBe(hidden);
    });

    describe('when switching tabs', () => {
      const SCROLL_TOP = 100;

      beforeEach(() => {
        testContext.class.mergeRequestTabs = document.createElement('div');
        testContext.class.mergeRequestTabPanes = document.createElement('div');
        testContext.class.currentTab = 'tab';
        testContext.class.scrollPositions = { newTab: SCROLL_TOP };
      });

      it('scrolls to the stored position, if one is stored', () => {
        testContext.class.tabShown('newTab');

        jest.advanceTimersByTime(250);

        expect(scrollTo.mock.calls[0][0]).toEqual({
          top: SCROLL_TOP,
          left: 0,
          behavior: 'auto',
        });
      });

      it('does not scroll if no position is stored', () => {
        testContext.class.tabShown('unknownTab');

        jest.advanceTimersByTime(250);

        expect(scrollTo).not.toHaveBeenCalled();
      });
    });

    describe('switching to the diffs tab', () => {
      useMockInternalEventsTracking();

      describe('Rapid Diffs', () => {
        let createRapidDiffsApp;
        let init;
        let hide;
        let show;

        beforeEach(() => {
          setWindowLocation('https://example.com');
          const rdApp = document.createElement('article');
          rdApp.dataset.rapidDiffs = 'true';
          rdApp.dataset.appData = JSON.stringify({
            versions: {
              source_versions: [{ selected: true, base_sha: 'abc', head_sha: 'def' }],
              target_versions: [{ selected: true, start_sha: 'ghi' }],
            },
          });
          document.querySelector.mockImplementation((selector) => {
            if (selector === '[data-rapid-diffs]') return rdApp;
            if (selector === '.content-wrapper') return mainContent;
            return tabContent;
          });
          init = jest.fn();
          hide = jest.fn();
          show = jest.fn();
          createRapidDiffsApp = jest.fn(() => ({
            init,
            hide,
            show,
          }));
        });

        it('starts Rapid Diffs app', async () => {
          testContext.class = new MergeRequestTabs({
            stubLocation,
            createRapidDiffsApp,
          });
          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          expect(createRapidDiffsApp).toHaveBeenCalledTimes(1);
          expect(init).toHaveBeenCalledTimes(1);
        });

        it('creates a single Rapid Diffs app instance', async () => {
          testContext.class = new MergeRequestTabs({
            stubLocation,
            createRapidDiffsApp,
          });
          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          await testContext.class.tabShown('new', 'not-a-vue-page');
          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          expect(createRapidDiffsApp).toHaveBeenCalledTimes(1);
          expect(init).toHaveBeenCalledTimes(1);
        });

        it('hides Rapid Diffs', async () => {
          testContext.class = new MergeRequestTabs({
            stubLocation,
            createRapidDiffsApp,
          });
          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          await testContext.class.tabShown('new', 'not-a-vue-page');
          expect(hide).toHaveBeenCalledTimes(1);
        });

        it('shows Rapid Diffs', async () => {
          testContext.class = new MergeRequestTabs({
            stubLocation,
            createRapidDiffsApp,
          });
          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          await testContext.class.tabShown('new', 'not-a-vue-page');
          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          expect(show).toHaveBeenCalledTimes(1);
        });

        it('tracks the Rapid Diffs SPA visit once', async () => {
          testContext.class = new MergeRequestTabs({ stubLocation, createRapidDiffsApp });

          await testContext.class.tabShown('diffs', 'not-a-vue-page');
          await testContext.class.tabShown('new', 'not-a-vue-page');
          await testContext.class.tabShown('diffs', 'not-a-vue-page');

          expect(InternalEvents.trackEvent).toHaveBeenCalledTimes(1);
          expect(InternalEvents.trackEvent).toHaveBeenCalledWith('view_merge_request_diffs', {
            label: 'rapid_diffs',
            property: 'spa_navigation',
          });
        });

        it('does not track Rapid Diffs when the diffs tab was the backend-rendered page', async () => {
          testContext.class = new MergeRequestTabs({
            action: 'diffs',
            stubLocation,
            createRapidDiffsApp,
          });

          await testContext.class.tabShown('diffs', '/diffs');

          expect(createRapidDiffsApp).toHaveBeenCalledTimes(1);
          expect(InternalEvents.trackEvent).not.toHaveBeenCalled();
        });

        describe('when diff refs are missing', () => {
          let rdAppNoDiffs;

          beforeEach(() => {
            rdAppNoDiffs = document.createElement('article');
            rdAppNoDiffs.dataset.rapidDiffs = 'true';
            rdAppNoDiffs.dataset.appData = JSON.stringify({ versions: null });
            document.querySelector.mockImplementation((selector) => {
              if (selector === '[data-rapid-diffs]') return rdAppNoDiffs;
              if (selector === '.js-merge-request-new-submit') return null;
              if (selector === '.content-wrapper') return mainContent;
              return tabContent;
            });
          });

          it('navigates to full page instead of SPA when clicking diffs tab', () => {
            testContext.class = new MergeRequestTabs({
              stubLocation,
              createRapidDiffsApp,
            });
            const diffsHref = '/project/-/merge_requests/1/diffs';
            testContext.class.clickTab({
              stopImmediatePropagation: jest.fn(),
              preventDefault: jest.fn(),
              currentTarget: {
                dataset: { action: 'diffs' },
                getAttribute: () => diffsHref,
              },
            });
            expect(visitUrl).toHaveBeenCalledWith(diffsHref);
            expect(createRapidDiffsApp).not.toHaveBeenCalled();
          });

          it('does not redirect on initial page load', async () => {
            testContext.class = new MergeRequestTabs({
              action: 'diffs',
              stubLocation,
              createRapidDiffsApp,
            });
            await testContext.class.tabShown('diffs', '/diffs');
            expect(createRapidDiffsApp).toHaveBeenCalledTimes(1);
          });
        });
      });

      describe('legacy diffs', () => {
        let originalDiffsBundle;

        beforeEach(() => {
          originalDiffsBundle = pageBundles.diffs;
          pageBundles.diffs = jest.fn(() => Promise.resolve({ default: jest.fn() }));
          jest.spyOn(domUtils, 'isInVueNoteablePage').mockReturnValue(true);
        });

        afterEach(() => {
          pageBundles.diffs = originalDiffsBundle;
        });

        it('tracks the legacy diffs SPA visit when the bundle loads', async () => {
          testContext.class = new MergeRequestTabs({ action: 'show', stubLocation });

          await testContext.class.tabShown('diffs', '/diffs');

          expect(InternalEvents.trackEvent).toHaveBeenCalledWith('view_merge_request_diffs', {
            label: 'legacy_diffs',
            property: 'spa_navigation',
          });
        });

        it('does not track when the bundle is already loaded', async () => {
          testContext.class = new MergeRequestTabs({ action: 'diffs', stubLocation });

          await testContext.class.tabShown('diffs', '/diffs');

          expect(InternalEvents.trackEvent).not.toHaveBeenCalled();
        });
      });
    });

    describe('trackSpaVisit', () => {
      useMockInternalEventsTracking();

      it.each(['rapid_diffs', 'legacy_diffs'])(
        'fires view_merge_request_diffs internal event with %s label',
        (label) => {
          testContext.class.trackSpaVisit(label);

          expect(InternalEvents.trackEvent).toHaveBeenCalledWith('view_merge_request_diffs', {
            label,
            property: 'spa_navigation',
          });
        },
      );
    });

    describe('destroyPipelines', () => {
      beforeEach(() => {
        testContext.class.mergeRequestTabs = document.createElement('div');
        testContext.class.mergeRequestTabPanes = document.createElement('div');
        testContext.class.currentTab = 'pipelines';
        testContext.class.commitsTab = document.createElement('div');
        testContext.class.mergeRequestPipelinesTable = { $destroy: jest.fn() };
        document.body.innerHTML += '<div id="commit-pipeline-table-view"></div>';
      });

      afterEach(() => {
        document.querySelector('#commit-pipeline-table-view')?.remove();
      });

      it.each`
        tab
        ${'commits'}
        ${'new'}
        ${'diffs'}
        ${'reports'}
        ${'show'}
      `('destroys pipelines when switching to $tab tab', ({ tab }) => {
        const { $destroy } = testContext.class.mergeRequestPipelinesTable;

        testContext.class.tabShown(tab, 'foobar');

        expect($destroy).toHaveBeenCalled();
        expect(testContext.class.mergeRequestPipelinesTable).toBeNull();
      });

      it('does not destroy pipelines when switching to pipelines tab', () => {
        const { $destroy } = testContext.class.mergeRequestPipelinesTable;

        testContext.class.tabShown('pipelines', 'foobar');

        expect($destroy).not.toHaveBeenCalled();
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

  describe('getActionFromHref', () => {
    it.each`
      pathName                                               | action
      ${'/user/pipelines/-/merge_requests/1/diffs'}          | ${'diffs'}
      ${'/user/diffs/-/merge_requests/1/pipelines'}          | ${'pipelines'}
      ${'/user/pipelines/-/merge_requests/1/commits'}        | ${'commits'}
      ${'/user/pipelines/1/-/merge_requests/1/diffs'}        | ${'diffs'}
      ${'/user/gitlab/-/merge_requests/new/diffs'}           | ${'diffs'}
      ${'/user/pipelines/-/merge_requests/1'}                | ${'show'}
      ${'/user/pipelines/-/merge_requests/1/reports'}        | ${'reports'}
      ${'/group/reports/project/-/merge_requests/1/reports'} | ${'reports'}
    `('returns $action for $location', ({ pathName, action }) => {
      expect(getActionFromHref(pathName)).toBe(action);
    });
  });

  describe('navigateToDiffNote', () => {
    const discussion = {
      active: true,
      notes: [{ id: '100' }],
      discussion_path: '/project/-/merge_requests/1/diffs#abc',
      original_position: {
        base_sha: 'abc',
        head_sha: 'def',
        start_sha: 'ghi',
        old_path: 'old/file.js',
        new_path: 'new/file.js',
      },
    };

    beforeEach(() => {
      setHTMLFixture(htmlMergeRequestsWithTaskList);
      testContext.class = new MergeRequestTabs({ stubLocation });
      testContext.class.createRapidDiffsApp = jest.fn();
    });

    describe('legacy fallbacks', () => {
      it('follows discussion_path when Rapid Diffs is not enabled', async () => {
        testContext.class.createRapidDiffsApp = null;
        await testContext.class.navigateToDiffNote(discussion);
        expect(visitUrl).toHaveBeenCalledWith(discussion.discussion_path);
      });

      it.each(['for_commit', 'commit_id'])(
        'navigates to legacy diffs when discussion has %s',
        async (field) => {
          const disc = { ...discussion, [field]: 'abc123' };
          await testContext.class.navigateToDiffNote(disc);
          const url = new URL(visitUrl.mock.calls[0][0]);
          expect(url.searchParams.get('rapid_diffs_disabled')).toBe('true');
          expect(url.searchParams.get('reason')).toBe('unsupported');
        },
      );

      it('navigates to legacy diffs when discussion has no position', async () => {
        const disc = { ...discussion, original_position: undefined, position: undefined };
        await testContext.class.navigateToDiffNote(disc);
        const url = new URL(visitUrl.mock.calls[0][0]);
        expect(url.searchParams.get('rapid_diffs_disabled')).toBe('true');
      });
    });

    describe('full page navigation', () => {
      it('navigates when discussion is not active and app is not loaded', async () => {
        const disc = { ...discussion, active: false };
        await testContext.class.navigateToDiffNote(disc);
        const url = new URL(visitUrl.mock.calls[0][0]);
        expect(url.pathname).toBe('/project/-/merge_requests/1/diffs');
      });

      it('navigates when app is loaded but version does not match', async () => {
        testContext.class.rapidDiffsApp = { scrollToDiffNote: jest.fn() };
        useMergeRequestVersions().$patch({
          sourceVersions: [{ selected: true, base_sha: 'x', head_sha: 'y' }],
          targetVersions: [{ selected: true, start_sha: 'z' }],
        });
        await testContext.class.navigateToDiffNote(discussion);
        expect(visitUrl).toHaveBeenCalled();
      });

      it('includes linked file params from discussion position', async () => {
        const disc = { ...discussion, active: false };
        await testContext.class.navigateToDiffNote(disc);
        const url = new URL(visitUrl.mock.calls[0][0]);
        expect(url.searchParams.get('old_path')).toBe('old/file.js');
        expect(url.searchParams.get('new_path')).toBe('new/file.js');
      });

      it('includes note hash', async () => {
        const disc = { ...discussion, active: false };
        await testContext.class.navigateToDiffNote(disc);
        const url = new URL(visitUrl.mock.calls[0][0]);
        expect(url.hash).toBe('#note_100');
      });

      it('uses file_path when paths are the same', async () => {
        const disc = {
          ...discussion,
          active: false,
          original_position: {
            ...discussion.original_position,
            old_path: 'same.js',
            new_path: 'same.js',
          },
        };
        await testContext.class.navigateToDiffNote(disc);
        const url = new URL(visitUrl.mock.calls[0][0]);
        expect(url.searchParams.get('file_path')).toBe('same.js');
        expect(url.searchParams.has('old_path')).toBe(false);
      });
    });

    describe('SPA navigation when app loaded with matching older version', () => {
      it('does not full-page navigate', async () => {
        testContext.class.rapidDiffsApp = { scrollToDiffNote: jest.fn() };
        useMergeRequestVersions().$patch({
          sourceVersions: [{ selected: true, base_sha: 'abc', head_sha: 'def' }],
          targetVersions: [{ selected: true, version_index: 1, start_sha: 'ghi' }],
        });
        jest.spyOn(testContext.class, 'tabShown').mockResolvedValue();
        const disc = { ...discussion, active: false };
        await testContext.class.navigateToDiffNote(disc);
        expect(visitUrl).not.toHaveBeenCalled();
        expect(testContext.class.rapidDiffsApp.scrollToDiffNote).toHaveBeenCalledWith(disc);
      });
    });

    describe('SPA navigation', () => {
      const navigate = () => testContext.class.navigateToDiffNote(discussion);

      beforeEach(() => {
        useMergeRequestVersions().$reset();
        jest.spyOn(testContext.class, 'tabShown').mockImplementation(() => {
          testContext.class.rapidDiffsApp ||= { scrollToDiffNote: jest.fn() };
          return Promise.resolve();
        });
      });

      it('stores scroll position before switching tabs', async () => {
        jest.spyOn(testContext.class, 'storeScroll');
        await navigate();
        expect(testContext.class.storeScroll).toHaveBeenCalled();
      });

      it('sets note hash in URL', async () => {
        const replaceStateSpy = jest.spyOn(window.history, 'replaceState');
        await navigate();
        expect(replaceStateSpy).toHaveBeenCalledWith(
          null,
          '',
          expect.objectContaining({ hash: '#note_100' }),
        );
      });

      it('switches to diffs tab and scrolls to note position', async () => {
        await navigate();
        expect(testContext.class.tabShown).toHaveBeenCalledWith('diffs', null, false);
        expect(testContext.class.rapidDiffsApp.scrollToDiffNote).toHaveBeenCalledWith(discussion);
      });

      it('does not call visitUrl', async () => {
        await navigate();
        expect(visitUrl).not.toHaveBeenCalled();
      });

      it('sets linked file data on store when app is not yet loaded', async () => {
        const store = useDiffsList();
        jest.spyOn(store, 'setLinkedFileData');
        await navigate();
        expect(store.setLinkedFileData).toHaveBeenCalledWith({
          old_path: 'old/file.js',
          new_path: 'new/file.js',
        });
      });

      it('does not set linked file data when app is already loaded', async () => {
        testContext.class.rapidDiffsApp = { scrollToDiffNote: jest.fn() };
        const store = useDiffsList();
        jest.spyOn(store, 'setLinkedFileData');
        await navigate();
        expect(store.setLinkedFileData).not.toHaveBeenCalled();
      });
    });
  });

  it('does not scroll to targets with no scroll class', () => {
    setHTMLFixture(htmlMergeRequestsWithTaskList);
    const target = document.createElement('div');
    target.id = 'target';
    target.classList.add(NO_SCROLL_TO_HASH_CLASS);
    document.body.appendChild(target);
    testContext.class.currentAction = 'show';
    window.location.hash = 'target';

    // popstate event handlers are not triggered in the same task
    jest.runAllTimers();
    expect(scrollTo).not.toHaveBeenCalled();
  });
});
