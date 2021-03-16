import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import initMrPage from 'helpers/init_vue_mr_page_helper';
import axios from '~/lib/utils/axios_utils';
import MergeRequestTabs from '~/merge_request_tabs';
import '~/lib/utils/common_utils';

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
    initMrPage();

    testContext.class = new MergeRequestTabs({ stubLocation });
    setLocation();

    testContext.spies = {
      history: jest.spyOn(window.history, 'pushState').mockImplementation(() => {}),
    };

    gl.mrWidget = {};
  });

  describe('opensInNewTab', () => {
    const windowTarget = '_blank';
    let clickTabParams;
    let tabUrl;

    beforeEach(() => {
      loadFixtures('merge_requests/merge_request_with_task_list.html');

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
      jest.spyOn(mainContent, 'getBoundingClientRect').mockReturnValue({ top: 10 });
      jest.spyOn(tabContent, 'getBoundingClientRect').mockReturnValue({ top: 100 });
      jest.spyOn(document, 'querySelector').mockImplementation((selector) => {
        return selector === '.content-wrapper' ? mainContent : tabContent;
      });
      testContext.class.currentAction = 'commits';
    });

    it('calls window scrollTo with options if document has scrollBehavior', () => {
      document.documentElement.style.scrollBehavior = '';

      jest.spyOn(window, 'scrollTo').mockImplementation(() => {});

      testContext.class.tabShown('commits', 'foobar');

      expect(window.scrollTo.mock.calls[0][0]).toEqual({ top: 39, behavior: 'smooth' });
    });

    it('calls window scrollTo with two args if document does not have scrollBehavior', () => {
      jest.spyOn(document.documentElement, 'style', 'get').mockReturnValue({});
      jest.spyOn(window, 'scrollTo').mockImplementation(() => {});

      testContext.class.tabShown('commits', 'foobar');

      expect(window.scrollTo.mock.calls[0]).toEqual([0, 39]);
    });
  });
});
