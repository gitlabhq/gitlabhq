import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

describe('PerformanceBarService', () => {
  describe('callbackParams', () => {
    describe('fireCallback', () => {
      function fireCallback(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[0];
      }

      it('returns false when the request URL is the peek URL', () => {
        expect(
          fireCallback({ headers: { 'x-request-id': '123' }, config: { url: '/peek' } }, '/peek'),
        ).toBe(false);
      });

      it('returns false when there is no request ID', () => {
        expect(fireCallback({ headers: {}, config: { url: '/request' } }, '/peek')).toBe(false);
      });

      it('returns false when the response is from the cache', () => {
        expect(
          fireCallback(
            { headers: { 'x-request-id': '123', 'x-gitlab-from-cache': 'true' }, url: '/request' },
            '/peek',
          ),
        ).toBe(false);
      });

      it('returns true when the request is an API request', () => {
        expect(
          fireCallback({ headers: { 'x-request-id': '123' }, config: { url: '/api/' } }, '/peek'),
        ).toBe(true);
      });

      it('returns true for all other requests', () => {
        expect(
          fireCallback(
            { headers: { 'x-request-id': '123' }, config: { url: '/request' } },
            '/peek',
          ),
        ).toBe(true);
      });
    });

    describe('requestId', () => {
      function requestId(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[1];
      }

      it('gets the request ID from the headers', () => {
        expect(requestId({ headers: { 'x-request-id': '123' } }, '/peek')).toBe('123');
      });
    });

    describe('requestUrl', () => {
      function requestUrl(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[2];
      }

      it('gets the request URL from response.config', () => {
        expect(requestUrl({ headers: {}, config: { url: '/config-url' } }, '/peek')).toBe(
          '/config-url',
        );
      });
    });

    describe('operationName', () => {
      function requestUrl(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[4];
      }

      it('gets the operation name from response.config', () => {
        expect(
          requestUrl({ headers: {}, config: { operationName: 'someOperation' } }, '/peek'),
        ).toBe('someOperation');
      });
    });
  });
});
