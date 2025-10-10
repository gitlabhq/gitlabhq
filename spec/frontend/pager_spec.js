import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { removeParams } from '~/lib/utils/url_utility';
import Pager from '~/pager';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  removeParams: jest.fn().mockName('removeParams'),
}));

describe('pager', () => {
  let axiosMock;

  beforeEach(() => {
    window.gon = {
      features: {
        projectStudioEnabled: false,
      },
    };
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('init', () => {
    const originalHref = window.location.href;

    beforeEach(() => {
      setHTMLFixture('<div class="content_list"></div><div class="loading"></div>');
      jest.spyOn($.fn, 'endlessScroll').mockImplementation();
      jest.spyOn(Pager, 'initLoadMoreForProjectStudio');
    });

    afterEach(() => {
      window.history.replaceState({}, null, originalHref);

      resetHTMLFixture();
    });

    it('should get initial offset from query parameter', () => {
      window.history.replaceState({}, null, '?offset=100');
      Pager.init();

      expect(Pager.offset).toBe(100);
    });

    it('should setup scroll container listener for project studio when projectStudioEnabled is true', () => {
      window.gon = {
        features: { projectStudioEnabled: true },
      };

      window.history.replaceState({}, null, '?offset=100');
      Pager.init();

      expect(Pager.initLoadMoreForProjectStudio).toHaveBeenCalled();
      expect(Pager.loadingObserver).toBeInstanceOf(IntersectionObserver);
    });
  });

  describe('getOld', () => {
    const urlRegex = /(.*)some_list(.*)$/;

    function mockSuccess(count = 0) {
      axiosMock.onGet(urlRegex).reply(HTTP_STATUS_OK, {
        count,
        html: '',
      });
    }

    function mockError() {
      axiosMock.onGet(urlRegex).networkError();
    }

    beforeEach(() => {
      setHTMLFixture(
        '<div class="content_list" data-href="/some_list"></div><div class="loading"></div>',
      );
      jest.spyOn(axios, 'get');

      Pager.init();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('shows loader while loading next page', async () => {
      mockSuccess();

      jest.spyOn(Pager.$loading, 'show').mockImplementation(() => {});
      Pager.getOld();

      await waitForPromises();

      expect(Pager.$loading.show).toHaveBeenCalled();
    });

    it('hides loader on success', async () => {
      mockSuccess();

      jest.spyOn(Pager.$loading, 'hide').mockImplementation(() => {});
      Pager.getOld();

      await waitForPromises();

      expect(Pager.$loading.hide).toHaveBeenCalled();
    });

    it('hides loader on error', async () => {
      mockError();

      jest.spyOn(Pager.$loading, 'hide').mockImplementation(() => {});
      Pager.getOld();

      await waitForPromises();

      expect(Pager.$loading.hide).toHaveBeenCalled();
    });

    it('sends request to url with offset and limit params', async () => {
      Pager.offset = 100;
      Pager.limit = 20;
      Pager.getOld();

      await waitForPromises();

      const [url, params] = axios.get.mock.calls[0];

      expect(params).toEqual({
        params: {
          limit: 20,
          offset: 100,
        },
      });

      expect(url).toBe('/some_list');
    });

    it('disables if return count is less than limit', async () => {
      Pager.offset = 0;
      Pager.limit = 20;

      mockSuccess(1);
      jest.spyOn(Pager.$loading, 'hide').mockImplementation(() => {});
      Pager.getOld();

      await waitForPromises();

      expect(Pager.$loading.hide).toHaveBeenCalled();
      expect(Pager.disable).toBe(true);
    });

    describe('has data-href attribute from list element', () => {
      const href = `${TEST_HOST}/some_list.json`;

      beforeEach(() => {
        setHTMLFixture(`<div class="content_list" data-href="${href}"></div>`);
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('should use data-href attribute', () => {
        Pager.getOld();

        expect(axios.get).toHaveBeenCalledWith(href, expect.any(Object));
      });

      it('should not use current url', () => {
        Pager.getOld();

        expect(removeParams).not.toHaveBeenCalled();
        expect(removeParams).not.toHaveBeenCalledWith(href);
      });
    });

    describe('no data-href attribute attribute provided from list element', () => {
      beforeEach(() => {
        setHTMLFixture(`<div class="content_list"></div>`);
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('should use current url', () => {
        const href = `${TEST_HOST}/some_list`;
        removeParams.mockReturnValue(href);
        Pager.getOld();

        expect(axios.get).toHaveBeenCalledWith(href, expect.any(Object));
      });

      it('keeps extra query parameters from url', () => {
        window.history.replaceState({}, null, '?filter=test&offset=100');
        const href = `${TEST_HOST}/some_list?filter=test`;
        removeParams.mockReturnValue(href);
        Pager.getOld();

        expect(removeParams).toHaveBeenCalledWith(['limit', 'offset']);
        expect(axios.get).toHaveBeenCalledWith(href, expect.any(Object));
      });
    });

    describe('when `container` is passed', () => {
      const href = '/some_list';
      const container = '#js-pager';
      let endlessScrollCallback;

      beforeEach(() => {
        jest.spyOn(axios, 'get');
        jest.spyOn($.fn, 'endlessScroll').mockImplementation(({ callback }) => {
          endlessScrollCallback = callback;
        });
      });

      describe('when `container` is visible', () => {
        it('makes API request', () => {
          setHTMLFixture(
            `<div id="js-pager"><div class="content_list" data-href="${href}"></div></div>`,
          );

          Pager.init({ container });

          endlessScrollCallback();

          expect(axios.get).toHaveBeenCalledWith(href, expect.any(Object));

          resetHTMLFixture();
        });
      });

      describe('when `container` is not visible', () => {
        it('does not make API request', () => {
          setHTMLFixture(
            `<div id="js-pager" style="display: none;"><div class="content_list" data-href="${href}"></div></div>`,
          );

          Pager.init({ container });

          endlessScrollCallback();

          expect(axios.get).not.toHaveBeenCalled();

          resetHTMLFixture();
        });
      });
    });
  });

  describe('isScrollable', () => {
    describe('when projectStudioEnabled is true', () => {
      const applyMockHeights = (container, { scrollHeight, clientHeight }) => {
        // We need to set these values manually as JSDom won't compute
        // CSS that causes scroller to appear based on content height
        Object.defineProperties(container, {
          scrollHeight: { value: scrollHeight },
          clientHeight: { value: clientHeight },
          scrollTop: { value: 0 },
        });
      };

      beforeEach(() => {
        setHTMLFixture('<div class="content_list"></div><div class="loading"></div>');
        window.gon = {
          features: { projectStudioEnabled: true },
        };

        Pager.init();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('returns true when container is scrollable', () => {
        setHTMLFixture(`
          <div class="js-static-panel-inner" style="height: 800px; overflow: auto;">
            <div style="height: 2000px;"></div>
          </div>
        `);

        applyMockHeights(document.querySelector('.js-static-panel-inner'), {
          scrollHeight: 2000,
          clientHeight: 800,
        });

        expect(Pager.isScrollable()).toBe(true);
      });

      it('returns false when container is not scrollable', () => {
        setHTMLFixture(`
          <div class="js-static-panel-inner" style="height: 800px;"></div>
        `);

        applyMockHeights(document.querySelector('.js-static-panel-inner'), {
          scrollHeight: 800,
          clientHeight: 800,
        });

        expect(Pager.isScrollable()).toBe(false);
      });

      it('returns false when container does not exist', () => {
        expect(Pager.isScrollable()).toBe(false);
      });
    });
  });
});
