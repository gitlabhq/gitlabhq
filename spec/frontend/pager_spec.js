import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { removeParams } from '~/lib/utils/url_utility';
import Pager from '~/pager';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  removeParams: jest.fn().mockName('removeParams'),
}));

describe('pager', () => {
  let axiosMock;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('init', () => {
    const originalHref = window.location.href;

    beforeEach(() => {
      setFixtures('<div class="content_list"></div><div class="loading"></div>');
      jest.spyOn($.fn, 'endlessScroll').mockImplementation();
    });

    afterEach(() => {
      window.history.replaceState({}, null, originalHref);
    });

    it('should get initial offset from query parameter', () => {
      window.history.replaceState({}, null, '?offset=100');
      Pager.init();

      expect(Pager.offset).toBe(100);
    });
  });

  describe('getOld', () => {
    const urlRegex = /(.*)some_list(.*)$/;

    function mockSuccess(count = 0) {
      axiosMock.onGet(urlRegex).reply(200, {
        count,
        html: '',
      });
    }

    function mockError() {
      axiosMock.onGet(urlRegex).networkError();
    }

    beforeEach(() => {
      setFixtures(
        '<div class="content_list" data-href="/some_list"></div><div class="loading"></div>',
      );
      jest.spyOn(axios, 'get');

      Pager.init();
    });

    it('shows loader while loading next page', (done) => {
      mockSuccess();

      jest.spyOn(Pager.loading, 'show').mockImplementation(() => {});
      Pager.getOld();

      setImmediate(() => {
        expect(Pager.loading.show).toHaveBeenCalled();

        done();
      });
    });

    it('hides loader on success', (done) => {
      mockSuccess();

      jest.spyOn(Pager.loading, 'hide').mockImplementation(() => {});
      Pager.getOld();

      setImmediate(() => {
        expect(Pager.loading.hide).toHaveBeenCalled();

        done();
      });
    });

    it('hides loader on error', (done) => {
      mockError();

      jest.spyOn(Pager.loading, 'hide').mockImplementation(() => {});
      Pager.getOld();

      setImmediate(() => {
        expect(Pager.loading.hide).toHaveBeenCalled();

        done();
      });
    });

    it('sends request to url with offset and limit params', (done) => {
      Pager.offset = 100;
      Pager.limit = 20;
      Pager.getOld();

      setImmediate(() => {
        const [url, params] = axios.get.mock.calls[0];

        expect(params).toEqual({
          params: {
            limit: 20,
            offset: 100,
          },
        });

        expect(url).toBe('/some_list');

        done();
      });
    });

    it('disables if return count is less than limit', (done) => {
      Pager.offset = 0;
      Pager.limit = 20;

      mockSuccess(1);
      jest.spyOn(Pager.loading, 'hide').mockImplementation(() => {});
      Pager.getOld();

      setImmediate(() => {
        expect(Pager.loading.hide).toHaveBeenCalled();
        expect(Pager.disable).toBe(true);

        done();
      });
    });

    describe('has data-href attribute from list element', () => {
      const href = `${TEST_HOST}/some_list.json`;

      beforeEach(() => {
        setFixtures(`<div class="content_list" data-href="${href}"></div>`);
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
        setFixtures(`<div class="content_list"></div>`);
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
  });
});
