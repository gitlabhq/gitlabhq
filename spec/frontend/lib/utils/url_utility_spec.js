import { TEST_HOST } from 'helpers/test_constants';
import * as urlUtils from '~/lib/utils/url_utility';

const shas = {
  valid: [
    'ad9be38573f9ee4c4daec22673478c2dd1d81cd8',
    '76e07a692f65a2f4fd72f107a3e83908bea9b7eb',
    '9dd8f215b1e8605b1d59eaf9df1178081cda0aaf',
    'f2e0be58c4091b033203bae1cc0302febd54117d',
  ],
  invalid: [
    'zd9be38573f9ee4c4daec22673478c2dd1d81cd8',
    ':6e07a692f65a2f4fd72f107a3e83908bea9b7eb',
    '-dd8f215b1e8605b1d59eaf9df1178081cda0aaf',
    ' 2e0be58c4091b033203bae1cc0302febd54117d',
  ],
};

const setWindowLocation = (value) => {
  Object.defineProperty(window, 'location', {
    writable: true,
    value,
  });
};

describe('URL utility', () => {
  let originalLocation;

  beforeAll(() => {
    originalLocation = window.location;
  });

  afterAll(() => {
    window.location = originalLocation;
  });

  describe('webIDEUrl', () => {
    afterEach(() => {
      gon.relative_url_root = '';
    });

    it('escapes special characters', () => {
      expect(urlUtils.webIDEUrl('/gitlab-org/gitlab-#-foss/merge_requests/1')).toBe(
        '/-/ide/project/gitlab-org/gitlab-%23-foss/merge_requests/1',
      );
    });

    describe('without relative_url_root', () => {
      it('returns IDE path with route', () => {
        expect(urlUtils.webIDEUrl('/gitlab-org/gitlab-foss/merge_requests/1')).toBe(
          '/-/ide/project/gitlab-org/gitlab-foss/merge_requests/1',
        );
      });
    });

    describe('with relative_url_root', () => {
      beforeEach(() => {
        gon.relative_url_root = '/gitlab';
      });

      it('returns IDE path with route', () => {
        expect(urlUtils.webIDEUrl('/gitlab/gitlab-org/gitlab-foss/merge_requests/1')).toBe(
          '/gitlab/-/ide/project/gitlab-org/gitlab-foss/merge_requests/1',
        );
      });
    });
  });

  describe('getParameterValues', () => {
    beforeEach(() => {
      setWindowLocation({
        href: 'https://gitlab.com?test=passing&multiple=1&multiple=2',
        // make our fake location act like real window.location.toString
        // URL() (used in getParameterValues) does this if passed an object
        toString() {
          return this.href;
        },
      });
    });

    it('returns empty array for no params', () => {
      expect(urlUtils.getParameterValues()).toEqual([]);
    });

    it('returns empty array for non-matching params', () => {
      expect(urlUtils.getParameterValues('notFound')).toEqual([]);
    });

    it('returns single match', () => {
      expect(urlUtils.getParameterValues('test')).toEqual(['passing']);
    });

    it('returns multiple matches', () => {
      expect(urlUtils.getParameterValues('multiple')).toEqual(['1', '2']);
    });

    it('accepts url as second arg', () => {
      const url = 'https://gitlab.com?everything=works';
      expect(urlUtils.getParameterValues('everything', url)).toEqual(['works']);
      expect(urlUtils.getParameterValues('test', url)).toEqual([]);
    });
  });

  describe('mergeUrlParams', () => {
    const { mergeUrlParams } = urlUtils;

    it('adds w', () => {
      expect(mergeUrlParams({ w: 1 }, '#frag')).toBe('?w=1#frag');
      expect(mergeUrlParams({ w: 1 }, '')).toBe('?w=1');
      expect(mergeUrlParams({ w: 1 }, '/path#frag')).toBe('/path?w=1#frag');
      expect(mergeUrlParams({ w: 1 }, 'https://host/path')).toBe('https://host/path?w=1');
      expect(mergeUrlParams({ w: 1 }, 'https://host/path#frag')).toBe('https://host/path?w=1#frag');
      expect(mergeUrlParams({ w: 1 }, 'https://h/p?k1=v1#frag')).toBe('https://h/p?k1=v1&w=1#frag');
      expect(mergeUrlParams({ w: 'null' }, '')).toBe('?w=null');
    });

    it('adds multiple params', () => {
      expect(mergeUrlParams({ a: 1, b: 2, c: 3 }, '#frag')).toBe('?a=1&b=2&c=3#frag');
    });

    it('updates w', () => {
      expect(mergeUrlParams({ w: 2 }, '/path?w=1#frag')).toBe('/path?w=2#frag');
      expect(mergeUrlParams({ w: 2 }, 'https://host/path?w=1')).toBe('https://host/path?w=2');
    });

    it('removes null w', () => {
      expect(mergeUrlParams({ w: null }, '?w=1#frag')).toBe('#frag');
      expect(mergeUrlParams({ w: null }, '/path?w=1#frag')).toBe('/path#frag');
      expect(mergeUrlParams({ w: null }, 'https://host/path?w=1')).toBe('https://host/path');
      expect(mergeUrlParams({ w: null }, 'https://host/path?w=1#frag')).toBe(
        'https://host/path#frag',
      );
      expect(mergeUrlParams({ w: null }, 'https://h/p?k1=v1&w=1#frag')).toBe(
        'https://h/p?k1=v1#frag',
      );
    });

    it('adds and updates encoded param values', () => {
      expect(mergeUrlParams({ foo: '&', q: '?' }, '?foo=%23#frag')).toBe('?foo=%26&q=%3F#frag');
      expect(mergeUrlParams({ foo: 'a value' }, '')).toBe('?foo=a%20value');
      expect(mergeUrlParams({ foo: 'a value' }, '?foo=1')).toBe('?foo=a%20value');
    });

    it('adds and updates encoded param names', () => {
      expect(mergeUrlParams({ 'a name': 1 }, '')).toBe('?a%20name=1');
      expect(mergeUrlParams({ 'a name': 2 }, '?a%20name=1')).toBe('?a%20name=2');
      expect(mergeUrlParams({ 'a name': null }, '?a%20name=1')).toBe('');
    });

    it('treats "+" as "%20"', () => {
      expect(mergeUrlParams({ ref: 'bogus' }, '?a=lorem+ipsum&ref=charlie')).toBe(
        '?a=lorem%20ipsum&ref=bogus',
      );
    });

    it('treats question marks and slashes as part of the query', () => {
      expect(mergeUrlParams({ ending: '!' }, '?ending=?&foo=bar')).toBe('?ending=!&foo=bar');
      expect(mergeUrlParams({ ending: '!' }, 'https://host/path?ending=?&foo=bar')).toBe(
        'https://host/path?ending=!&foo=bar',
      );
      expect(mergeUrlParams({ ending: '?' }, '?ending=!&foo=bar')).toBe('?ending=%3F&foo=bar');
      expect(mergeUrlParams({ ending: '?' }, 'https://host/path?ending=!&foo=bar')).toBe(
        'https://host/path?ending=%3F&foo=bar',
      );
      expect(mergeUrlParams({ ending: '!', op: '+' }, '?ending=?&op=/')).toBe('?ending=!&op=%2B');
      expect(mergeUrlParams({ ending: '!', op: '+' }, 'https://host/path?ending=?&op=/')).toBe(
        'https://host/path?ending=!&op=%2B',
      );
      expect(mergeUrlParams({ op: '+' }, '?op=/&foo=bar')).toBe('?op=%2B&foo=bar');
      expect(mergeUrlParams({ op: '+' }, 'https://host/path?op=/&foo=bar')).toBe(
        'https://host/path?op=%2B&foo=bar',
      );
    });

    it('sorts params in alphabetical order with sort option', () => {
      expect(mergeUrlParams({ c: 'c', b: 'b', a: 'a' }, 'https://host/path', { sort: true })).toBe(
        'https://host/path?a=a&b=b&c=c',
      );
      expect(
        mergeUrlParams({ alpha: 'alpha' }, 'https://host/path?op=/&foo=bar', { sort: true }),
      ).toBe('https://host/path?alpha=alpha&foo=bar&op=%2F');
    });

    describe('with spread array option', () => {
      const spreadArrayOptions = { spreadArrays: true };

      it('maintains multiple values', () => {
        expect(mergeUrlParams({}, '?array[]=foo&array[]=bar', spreadArrayOptions)).toBe(
          '?array[]=foo&array[]=bar',
        );
      });

      it('overrides multiple values with one', () => {
        expect(
          mergeUrlParams({ array: ['baz'] }, '?array[]=foo&array[]=bar', spreadArrayOptions),
        ).toBe('?array[]=baz');
      });
      it('removes existing params', () => {
        expect(
          mergeUrlParams({ array: null }, '?array[]=foo&array[]=bar', spreadArrayOptions),
        ).toBe('');
      });
      it('removes existing params and keeps others', () => {
        expect(
          mergeUrlParams(
            { array: null },
            '?array[]=foo&array[]=bar&other=quis',
            spreadArrayOptions,
          ),
        ).toBe('?other=quis');
      });
      it('removes existing params along others', () => {
        expect(
          mergeUrlParams(
            { array: null, other: 'quis' },
            '?array[]=foo&array[]=bar',
            spreadArrayOptions,
          ),
        ).toBe('?other=quis');
      });
      it('handles empty arrays along other parameters', () => {
        expect(mergeUrlParams({ array: [], other: 'quis' }, '?array=baz', spreadArrayOptions)).toBe(
          '?array[]=&other=quis',
        );
      });
      it('handles multiple values along other parameters', () => {
        expect(
          mergeUrlParams(
            { array: ['foo', 'bar'], other: 'quis' },
            '?array=baz',
            spreadArrayOptions,
          ),
        ).toBe('?array[]=foo&array[]=bar&other=quis');
      });
      it('handles array values with encoding', () => {
        expect(
          mergeUrlParams({ array: ['foo+', 'bar,baz'] }, '?array[]=%2Fbaz', spreadArrayOptions),
        ).toBe('?array[]=foo%2B&array[]=bar%2Cbaz');
      });
      it('handles multiple arrays', () => {
        expect(
          mergeUrlParams(
            { array1: ['foo+', 'bar,baz'], array2: ['quis', 'quux'] },
            '?array1[]=%2Fbaz',
            spreadArrayOptions,
          ),
        ).toBe('?array1[]=foo%2B&array1[]=bar%2Cbaz&array2[]=quis&array2[]=quux');
      });
    });

    describe('without spread array option', () => {
      it('maintains multiple values', () => {
        expect(mergeUrlParams({}, '?array=foo%2Cbar')).toBe('?array=foo%2Cbar');
      });
      it('overrides multiple values with one', () => {
        expect(mergeUrlParams({ array: ['baz'] }, '?array=foo%2Cbar')).toBe('?array=baz');
      });
      it('removes existing params', () => {
        expect(mergeUrlParams({ array: null }, '?array=foo%2Cbar')).toBe('');
      });
      it('removes existing params and keeps others', () => {
        expect(mergeUrlParams({ array: null }, '?array=foo&array=bar&other=quis')).toBe(
          '?other=quis',
        );
      });
      it('removes existing params along others', () => {
        expect(mergeUrlParams({ array: null, other: 'quis' }, '?array=foo&array=bar')).toBe(
          '?other=quis',
        );
      });
      it('handles empty arrays along other parameters', () => {
        expect(mergeUrlParams({ array: [], other: 'quis' }, '?array=baz')).toBe(
          '?array=&other=quis',
        );
      });
      it('handles multiple values along other parameters', () => {
        expect(mergeUrlParams({ array: ['foo', 'bar'], other: 'quis' }, '?array=baz')).toBe(
          '?array=foo%2Cbar&other=quis',
        );
      });
      it('handles array values with encoding', () => {
        expect(mergeUrlParams({ array: ['foo+', 'bar,baz'] }, '?array=%2Fbaz')).toBe(
          '?array=foo%2B%2Cbar%2Cbaz',
        );
      });
      it('handles multiple arrays', () => {
        expect(
          mergeUrlParams(
            { array1: ['foo+', 'bar,baz'], array2: ['quis', 'quux'] },
            '?array1=%2Fbaz',
          ),
        ).toBe('?array1=foo%2B%2Cbar%2Cbaz&array2=quis%2Cquux');
      });
    });
  });

  describe('removeParams', () => {
    describe('when url is passed', () => {
      it('removes query param with encoded ampersand', () => {
        const url = urlUtils.removeParams(['filter'], '/mail?filter=n%3Djoe%26l%3Dhome');

        expect(url).toBe('/mail');
      });

      it('should remove param when url has no other params', () => {
        const url = urlUtils.removeParams(['size'], '/feature/home?size=5');

        expect(url).toBe('/feature/home');
      });

      it('should remove param when url has other params', () => {
        const url = urlUtils.removeParams(['size'], '/feature/home?q=1&size=5&f=html');

        expect(url).toBe('/feature/home?q=1&f=html');
      });

      it('should remove param and preserve fragment', () => {
        const url = urlUtils.removeParams(['size'], '/feature/home?size=5#H2');

        expect(url).toBe('/feature/home#H2');
      });

      it('should remove multiple params', () => {
        const url = urlUtils.removeParams(['z', 'a'], '/home?z=11111&l=en_US&a=true#H2');

        expect(url).toBe('/home?l=en_US#H2');
      });
    });
  });

  describe('doesHashExistInUrl', () => {
    beforeEach(() => {
      setWindowLocation({
        hash: 'https://gitlab.com/gitlab-org/gitlab-test/issues/1#note_1',
      });
    });

    it('should return true when the given string exists in the URL hash', () => {
      expect(urlUtils.doesHashExistInUrl('note_')).toBe(true);
    });

    it('should return false when the given string does not exist in the URL hash', () => {
      expect(urlUtils.doesHashExistInUrl('doesnotexist')).toBe(false);
    });
  });

  describe('urlContainsSha', () => {
    it('returns true when there is a valid 40-character SHA1 hash in the URL', () => {
      shas.valid.forEach((sha) => {
        expect(
          urlUtils.urlContainsSha({ url: `http://urlstuff/${sha}/moreurlstuff` }),
        ).toBeTruthy();
      });
    });

    it('returns false when there is not a valid 40-character SHA1 hash in the URL', () => {
      shas.invalid.forEach((str) => {
        expect(urlUtils.urlContainsSha({ url: `http://urlstuff/${str}/moreurlstuff` })).toBeFalsy();
      });
    });
  });

  describe('getShaFromUrl', () => {
    let validUrls = [];
    let invalidUrls = [];

    beforeAll(() => {
      validUrls = shas.valid.map((sha) => `http://urlstuff/${sha}/moreurlstuff`);
      invalidUrls = shas.invalid.map((str) => `http://urlstuff/${str}/moreurlstuff`);
    });

    it('returns the valid 40-character SHA1 hash from the URL', () => {
      validUrls.forEach((url, idx) => {
        expect(urlUtils.getShaFromUrl({ url })).toBe(shas.valid[idx]);
      });
    });

    it('returns null from a URL with no valid 40-character SHA1 hash', () => {
      invalidUrls.forEach((url) => {
        expect(urlUtils.getShaFromUrl({ url })).toBeNull();
      });
    });
  });

  describe('setUrlFragment', () => {
    it('should set fragment when url has no fragment', () => {
      const url = urlUtils.setUrlFragment('/home/feature', 'usage');

      expect(url).toBe('/home/feature#usage');
    });

    it('should set fragment when url has existing fragment', () => {
      const url = urlUtils.setUrlFragment('/home/feature#overview', 'usage');

      expect(url).toBe('/home/feature#usage');
    });

    it('should set fragment when given fragment includes #', () => {
      const url = urlUtils.setUrlFragment('/home/feature#overview', '#install');

      expect(url).toBe('/home/feature#install');
    });
  });

  describe('updateHistory', () => {
    const state = { key: 'prop' };
    const title = 'TITLE';
    const url = 'URL';
    const win = {
      history: {
        pushState: jest.fn(),
        replaceState: jest.fn(),
      },
    };

    beforeEach(() => {
      win.history.pushState.mockReset();
      win.history.replaceState.mockReset();
    });

    it('should call replaceState if the replace option is true', () => {
      urlUtils.updateHistory({ state, title, url, replace: true, win });

      expect(win.history.replaceState).toHaveBeenCalledWith(state, title, url);
      expect(win.history.pushState).not.toHaveBeenCalled();
    });

    it('should call pushState if the replace option is missing', () => {
      urlUtils.updateHistory({ state, title, url, win });

      expect(win.history.replaceState).not.toHaveBeenCalled();
      expect(win.history.pushState).toHaveBeenCalledWith(state, title, url);
    });

    it('should call pushState if the replace option is false', () => {
      urlUtils.updateHistory({ state, title, url, replace: false, win });

      expect(win.history.replaceState).not.toHaveBeenCalled();
      expect(win.history.pushState).toHaveBeenCalledWith(state, title, url);
    });
  });

  describe('getBaseURL', () => {
    beforeEach(() => {
      setWindowLocation({
        protocol: 'https:',
        host: 'gitlab.com',
      });
    });

    it('returns correct base URL', () => {
      expect(urlUtils.getBaseURL()).toBe('https://gitlab.com');
    });
  });

  describe('isAbsolute', () => {
    it.each`
      url                                      | valid
      ${'https://gitlab.com/'}                 | ${true}
      ${'http://gitlab.com/'}                  | ${true}
      ${'/users/sign_in'}                      | ${false}
      ${' https://gitlab.com'}                 | ${false}
      ${'somepath.php?url=https://gitlab.com'} | ${false}
      ${'notaurl'}                             | ${false}
      ${'../relative_url'}                     | ${false}
      ${'<a></a>'}                             | ${false}
    `('returns $valid for $url', ({ url, valid }) => {
      expect(urlUtils.isAbsolute(url)).toBe(valid);
    });
  });

  describe('isRootRelative', () => {
    it.each`
      url                                       | valid
      ${'https://gitlab.com/'}                  | ${false}
      ${'http://gitlab.com/'}                   | ${false}
      ${'/users/sign_in'}                       | ${true}
      ${' https://gitlab.com'}                  | ${false}
      ${'/somepath.php?url=https://gitlab.com'} | ${true}
      ${'notaurl'}                              | ${false}
      ${'../relative_url'}                      | ${false}
      ${'<a></a>'}                              | ${false}
      ${'//other-host.test'}                    | ${false}
    `('returns $valid for $url', ({ url, valid }) => {
      expect(urlUtils.isRootRelative(url)).toBe(valid);
    });
  });

  describe('isAbsoluteOrRootRelative', () => {
    it.each`
      url                                       | valid
      ${'https://gitlab.com/'}                  | ${true}
      ${'http://gitlab.com/'}                   | ${true}
      ${'/users/sign_in'}                       | ${true}
      ${' https://gitlab.com'}                  | ${false}
      ${'/somepath.php?url=https://gitlab.com'} | ${true}
      ${'notaurl'}                              | ${false}
      ${'../relative_url'}                      | ${false}
      ${'<a></a>'}                              | ${false}
    `('returns $valid for $url', ({ url, valid }) => {
      expect(urlUtils.isAbsoluteOrRootRelative(url)).toBe(valid);
    });
  });

  describe('isExternal', () => {
    const gitlabUrl = 'https://gitlab.com/';

    beforeEach(() => {
      gon.gitlab_url = gitlabUrl;
    });

    afterEach(() => {
      gon.gitlab_url = '';
    });

    it.each`
      url                                        | urlType                    | external
      ${'/gitlab-org/gitlab-test/-/issues/2'}    | ${'relative'}              | ${false}
      ${gitlabUrl}                               | ${'absolute and internal'} | ${false}
      ${`${gitlabUrl}/gitlab-org/gitlab-test`}   | ${'absolute and internal'} | ${false}
      ${'http://jira.atlassian.net/browse/IG-1'} | ${'absolute and external'} | ${true}
    `('returns $external for $url ($urlType)', ({ url, external }) => {
      expect(urlUtils.isExternal(url)).toBe(external);
    });
  });

  describe('isBase64DataUrl', () => {
    it.each`
      url                                                      | valid
      ${undefined}                                             | ${false}
      ${'http://gitlab.com'}                                   | ${false}
      ${'data:image/png;base64,abcdef'}                        | ${true}
      ${'data:application/smil+xml;base64,abcdef'}             | ${true}
      ${'data:application/vnd.syncml+xml;base64,abcdef'}       | ${true}
      ${'data:application/vnd.3m.post-it-notes;base64,abcdef'} | ${true}
      ${'notaurl'}                                             | ${false}
      ${'../relative_url'}                                     | ${false}
      ${'<a></a>'}                                             | ${false}
    `('returns $valid for $url', ({ url, valid }) => {
      expect(urlUtils.isBase64DataUrl(url)).toBe(valid);
    });
  });

  describe('isBlobUrl', () => {
    it.each`
      url                               | valid
      ${undefined}                      | ${false}
      ${'blob:http://gitlab.com/abcd'}  | ${true}
      ${'data:image/png;base64,abcdef'} | ${false}
      ${'notaurl'}                      | ${false}
      ${'../relative_url'}              | ${false}
      ${'<a></a>'}                      | ${false}
    `('returns $valid for $url', ({ url, valid }) => {
      expect(urlUtils.isBlobUrl(url)).toBe(valid);
    });
  });

  describe('relativePathToAbsolute', () => {
    it.each`
      path                       | base                                  | result
      ${'./foo'}                 | ${'bar/'}                             | ${'/bar/foo'}
      ${'../john.md'}            | ${'bar/baz/foo.php'}                  | ${'/bar/john.md'}
      ${'../images/img.png'}     | ${'bar/baz/foo.php'}                  | ${'/bar/images/img.png'}
      ${'../images/Image 1.png'} | ${'bar/baz/foo.php'}                  | ${'/bar/images/Image 1.png'}
      ${'/images/img.png'}       | ${'bar/baz/foo.php'}                  | ${'/images/img.png'}
      ${'/images/img.png'}       | ${'/bar/baz/foo.php'}                 | ${'/images/img.png'}
      ${'../john.md'}            | ${'/bar/baz/foo.php'}                 | ${'/bar/john.md'}
      ${'../john.md'}            | ${'///bar/baz/foo.php'}               | ${'/bar/john.md'}
      ${'/images/img.png'}       | ${'https://gitlab.com/user/project/'} | ${'https://gitlab.com/images/img.png'}
      ${'../images/img.png'}     | ${'https://gitlab.com/user/project/'} | ${'https://gitlab.com/user/images/img.png'}
      ${'../images/Image 1.png'} | ${'https://gitlab.com/user/project/'} | ${'https://gitlab.com/user/images/Image%201.png'}
    `(
      'converts relative path "$path" with base "$base" to absolute path => "expected"',
      ({ path, base, result }) => {
        expect(urlUtils.relativePathToAbsolute(path, base)).toBe(result);
      },
    );
  });

  describe('isSafeUrl', () => {
    const absoluteUrls = [
      'http://example.org',
      'http://example.org:8080',
      'https://example.org',
      'https://example.org:8080',
      'https://192.168.1.1',
    ];

    const rootRelativeUrls = ['/relative/link'];

    const relativeUrls = ['./relative/link', '../relative/link'];

    const urlsWithoutHost = ['http://', 'https://', 'https:https:https:'];

    /* eslint-disable no-script-url */
    const nonHttpUrls = [
      'javascript:',
      'javascript:alert("XSS")',
      'jav\tascript:alert("XSS");',
      ' &#14;  javascript:alert("XSS");',
      'ftp://192.168.1.1',
      'file:///',
      'file:///etc/hosts',
    ];
    /* eslint-enable no-script-url */

    // javascript:alert('XSS')
    const encodedJavaScriptUrls = [
      '&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041',
      '&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;',
      '&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29',
      '\\u006A\\u0061\\u0076\\u0061\\u0073\\u0063\\u0072\\u0069\\u0070\\u0074\\u003A\\u0061\\u006C\\u0065\\u0072\\u0074\\u0028\\u0027\\u0058\\u0053\\u0053\\u0027\\u0029',
    ];

    const safeUrls = [...absoluteUrls, ...rootRelativeUrls];
    const unsafeUrls = [
      ...relativeUrls,
      ...urlsWithoutHost,
      ...nonHttpUrls,
      ...encodedJavaScriptUrls,
    ];

    describe('with URL constructor support', () => {
      it.each(safeUrls)('returns true for %s', (url) => {
        expect(urlUtils.isSafeURL(url)).toBe(true);
      });

      it.each(unsafeUrls)('returns false for %s', (url) => {
        expect(urlUtils.isSafeURL(url)).toBe(false);
      });
    });
  });

  describe('getWebSocketProtocol', () => {
    it.each`
      protocol    | expectation
      ${'http:'}  | ${'ws:'}
      ${'https:'} | ${'wss:'}
    `('returns "$expectation" with "$protocol" protocol', ({ protocol, expectation }) => {
      setWindowLocation({
        protocol,
        host: 'example.com',
      });

      expect(urlUtils.getWebSocketProtocol()).toEqual(expectation);
    });
  });

  describe('getWebSocketUrl', () => {
    it('joins location host to path', () => {
      setWindowLocation({
        protocol: 'http:',
        host: 'example.com',
      });

      const path = '/lorem/ipsum?a=bc';

      expect(urlUtils.getWebSocketUrl(path)).toEqual('ws://example.com/lorem/ipsum?a=bc');
    });
  });

  describe('urlParamsToArray', () => {
    it('returns empty array for empty querystring', () => {
      expect(urlUtils.urlParamsToArray('')).toEqual([]);
    });

    it('should decode params', () => {
      expect(urlUtils.urlParamsToArray('?label_name%5B%5D=test')[0]).toBe('label_name[]=test');
    });

    it('should remove the question mark from the search params', () => {
      const paramsArray = urlUtils.urlParamsToArray('?test=thing');

      expect(paramsArray[0][0]).not.toBe('?');
    });
  });

  describe('urlParamsToObject', () => {
    it('parses path for label with trailing +', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(urlUtils.urlParamsToObject('label_name[]=label%2B', {})).toEqual({
        label_name: ['label+'],
      });
    });

    it('parses path for milestone with trailing +', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(urlUtils.urlParamsToObject('milestone_title=A%2B', {})).toEqual({
        milestone_title: 'A+',
      });
    });

    it('parses path for search terms with spaces', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(urlUtils.urlParamsToObject('search=two+words', {})).toEqual({
        search: 'two words',
      });
    });
  });

  describe('queryToObject', () => {
    it.each`
      case                                                                      | query                             | options                                             | result
      ${'converts query'}                                                       | ${'?one=1&two=2'}                 | ${undefined}                                        | ${{ one: '1', two: '2' }}
      ${'converts query without ?'}                                             | ${'one=1&two=2'}                  | ${undefined}                                        | ${{ one: '1', two: '2' }}
      ${'removes undefined values'}                                             | ${'?one=1&two=2&three'}           | ${undefined}                                        | ${{ one: '1', two: '2' }}
      ${'overwrites values with same key and does not change key'}              | ${'?one[]=1&one[]=2&two=2&two=3'} | ${undefined}                                        | ${{ 'one[]': '2', two: '3' }}
      ${'gathers values with the same array-key, strips `[]` from key'}         | ${'?one[]=1&one[]=2&two=2&two=3'} | ${{ gatherArrays: true }}                           | ${{ one: ['1', '2'], two: '3' }}
      ${'overwrites values with the same array-key name'}                       | ${'?one=1&one[]=2&two=2&two=3'}   | ${{ gatherArrays: true }}                           | ${{ one: ['2'], two: '3' }}
      ${'overwrites values with the same key name'}                             | ${'?one[]=1&one=2&two=2&two=3'}   | ${{ gatherArrays: true }}                           | ${{ one: '2', two: '3' }}
      ${'ignores plus symbols'}                                                 | ${'?search=a+b'}                  | ${{ legacySpacesDecode: true }}                     | ${{ search: 'a+b' }}
      ${'ignores plus symbols in keys'}                                         | ${'?search+term=a'}               | ${{ legacySpacesDecode: true }}                     | ${{ 'search+term': 'a' }}
      ${'ignores plus symbols when gathering arrays'}                           | ${'?search[]=a+b'}                | ${{ gatherArrays: true, legacySpacesDecode: true }} | ${{ search: ['a+b'] }}
      ${'replaces plus symbols with spaces'}                                    | ${'?search=a+b'}                  | ${undefined}                                        | ${{ search: 'a b' }}
      ${'replaces plus symbols in keys with spaces'}                            | ${'?search+term=a'}               | ${undefined}                                        | ${{ 'search term': 'a' }}
      ${'replaces plus symbols when gathering arrays'}                          | ${'?search[]=a+b'}                | ${{ gatherArrays: true }}                           | ${{ search: ['a b'] }}
      ${'replaces plus symbols when gathering arrays for values with same key'} | ${'?search[]=a+b&search[]=c+d'}   | ${{ gatherArrays: true }}                           | ${{ search: ['a b', 'c d'] }}
    `('$case', ({ query, options, result }) => {
      expect(urlUtils.queryToObject(query, options)).toEqual(result);
    });
  });

  describe('getParameterByName', () => {
    const { getParameterByName } = urlUtils;

    it('should return valid parameter', () => {
      setWindowLocation({ search: '?scope=all&p=2' });

      expect(getParameterByName('p')).toEqual('2');
      expect(getParameterByName('scope')).toBe('all');
    });

    it('should return invalid parameter', () => {
      setWindowLocation({ search: '?scope=all&p=2' });

      expect(getParameterByName('fakeParameter')).toBe(null);
    });

    it('should return a parameter with spaces', () => {
      setWindowLocation({ search: '?search=my terms' });

      expect(getParameterByName('search')).toBe('my terms');
    });

    it('should return a parameter with encoded spaces', () => {
      setWindowLocation({ search: '?search=my%20terms' });

      expect(getParameterByName('search')).toBe('my terms');
    });

    it('should return a parameter with plus signs as spaces', () => {
      setWindowLocation({ search: '?search=my+terms' });

      expect(getParameterByName('search')).toBe('my terms');
    });

    it('should return valid parameters if search is provided', () => {
      expect(getParameterByName('foo', 'foo=bar')).toBe('bar');
      expect(getParameterByName('foo', '?foo=bar')).toBe('bar');

      expect(getParameterByName('manan', 'foo=bar&manan=canchu')).toBe('canchu');
      expect(getParameterByName('manan', '?foo=bar&manan=canchu')).toBe('canchu');
    });
  });

  describe('objectToQuery', () => {
    it('converts search query object back into a search query', () => {
      const searchQueryObject = { one: '1', two: '2' };

      expect(urlUtils.objectToQuery(searchQueryObject)).toEqual('one=1&two=2');
    });

    it('returns empty string when `params` is undefined, null or empty string', () => {
      expect(urlUtils.objectToQuery()).toBe('');
      expect(urlUtils.objectToQuery('')).toBe('');
    });

    it('returns query string with values of `params`', () => {
      const singleQueryParams = { foo: true };
      const multipleQueryParams = { foo: true, bar: true };

      expect(urlUtils.objectToQuery(singleQueryParams)).toBe('foo=true');
      expect(urlUtils.objectToQuery(multipleQueryParams)).toBe('foo=true&bar=true');
    });
  });

  describe('cleanLeadingSeparator', () => {
    it.each`
      path            | expected
      ${'/foo/bar'}   | ${'foo/bar'}
      ${'foo/bar'}    | ${'foo/bar'}
      ${'//foo/bar'}  | ${'foo/bar'}
      ${'/./foo/bar'} | ${'./foo/bar'}
      ${''}           | ${''}
    `('$path becomes $expected', ({ path, expected }) => {
      expect(urlUtils.cleanLeadingSeparator(path)).toBe(expected);
    });
  });

  describe('joinPaths', () => {
    it.each`
      paths                                       | expected
      ${['foo', 'bar']}                           | ${'foo/bar'}
      ${['foo/', 'bar']}                          | ${'foo/bar'}
      ${['foo//', 'bar']}                         | ${'foo/bar'}
      ${['abc/', '/def']}                         | ${'abc/def'}
      ${['foo', '/bar']}                          | ${'foo/bar'}
      ${['foo', '/bar/']}                         | ${'foo/bar/'}
      ${['foo', '//bar/']}                        | ${'foo/bar/'}
      ${['foo', '', '/bar']}                      | ${'foo/bar'}
      ${['foo', '/bar', '']}                      | ${'foo/bar'}
      ${['/', '', 'foo/bar/  ', '', '/ninja']}    | ${'/foo/bar/  /ninja'}
      ${['', '/ninja', '/', ' ', '', 'bar', ' ']} | ${'/ninja/ /bar/ '}
      ${['http://something/bar/', 'foo']}         | ${'http://something/bar/foo'}
      ${['foo/bar', null, 'ninja', null]}         | ${'foo/bar/ninja'}
      ${[null, 'abc/def', 'zoo']}                 | ${'abc/def/zoo'}
      ${['', '', '']}                             | ${''}
      ${['///', '/', '//']}                       | ${'/'}
    `('joins paths $paths => $expected', ({ paths, expected }) => {
      expect(urlUtils.joinPaths(...paths)).toBe(expected);
    });
  });

  describe('stripFinalUrlSegment', () => {
    it.each`
      path                                                        | expected
      ${'http://fake.domain/twitter/typeahead-js/-/tags/v0.11.0'} | ${'http://fake.domain/twitter/typeahead-js/-/tags/'}
      ${'http://fake.domain/bar/cool/-/nested/content'}           | ${'http://fake.domain/bar/cool/-/nested/'}
      ${'http://fake.domain/bar/cool?q="search"'}                 | ${'http://fake.domain/bar/'}
      ${'http://fake.domain/bar/cool#link-to-something'}          | ${'http://fake.domain/bar/'}
    `('stripFinalUrlSegment $path => $expected', ({ path, expected }) => {
      expect(urlUtils.stripFinalUrlSegment(path)).toBe(expected);
    });
  });

  describe('escapeFileUrl', () => {
    it('encodes URL excluding the slashes', () => {
      expect(urlUtils.escapeFileUrl('/foo-bar/file.md')).toBe('/foo-bar/file.md');
      expect(urlUtils.escapeFileUrl('foo bar/file.md')).toBe('foo%20bar/file.md');
      expect(urlUtils.escapeFileUrl('foo/bar/file.md')).toBe('foo/bar/file.md');
    });
  });

  describe('urlIsDifferent', () => {
    beforeEach(() => {
      setWindowLocation('current');
    });

    it('should compare against the window location if no compare value is provided', () => {
      expect(urlUtils.urlIsDifferent('different')).toBeTruthy();
      expect(urlUtils.urlIsDifferent('current')).toBeFalsy();
    });

    it('should use the provided compare value', () => {
      expect(urlUtils.urlIsDifferent('different', 'current')).toBeTruthy();
      expect(urlUtils.urlIsDifferent('current', 'current')).toBeFalsy();
    });
  });

  describe('setUrlParams', () => {
    it('adds new params as query string', () => {
      const url = 'https://gitlab.com/test';

      expect(
        urlUtils.setUrlParams({ group_id: 'gitlab-org', project_id: 'my-project' }, url),
      ).toEqual('https://gitlab.com/test?group_id=gitlab-org&project_id=my-project');
    });

    it('updates an existing parameter', () => {
      const url = 'https://gitlab.com/test?group_id=gitlab-org&project_id=my-project';

      expect(urlUtils.setUrlParams({ project_id: 'gitlab-test' }, url)).toEqual(
        'https://gitlab.com/test?group_id=gitlab-org&project_id=gitlab-test',
      );
    });

    it("removes the project_id param when it's value is null", () => {
      const url = 'https://gitlab.com/test?group_id=gitlab-org&project_id=my-project';

      expect(urlUtils.setUrlParams({ project_id: null }, url)).toEqual(
        'https://gitlab.com/test?group_id=gitlab-org',
      );
    });

    it('adds parameters from arrays', () => {
      const url = 'https://gitlab.com/test';

      expect(urlUtils.setUrlParams({ labels: ['foo', 'bar'] }, url)).toEqual(
        'https://gitlab.com/test?labels=foo&labels=bar',
      );
    });

    it('removes parameters from empty arrays', () => {
      const url = 'https://gitlab.com/test?labels=foo&labels=bar';

      expect(urlUtils.setUrlParams({ labels: [] }, url)).toEqual('https://gitlab.com/test');
    });

    it('removes parameters from empty arrays while keeping other parameters', () => {
      const url = 'https://gitlab.com/test?labels=foo&labels=bar&unrelated=unrelated';

      expect(urlUtils.setUrlParams({ labels: [] }, url)).toEqual(
        'https://gitlab.com/test?unrelated=unrelated',
      );
    });

    it('adds parameters from arrays when railsArraySyntax=true', () => {
      const url = 'https://gitlab.com/test';

      expect(urlUtils.setUrlParams({ labels: ['foo', 'bar'] }, url, false, true)).toEqual(
        'https://gitlab.com/test?labels%5B%5D=foo&labels%5B%5D=bar',
      );
    });

    it('removes parameters from empty arrays when railsArraySyntax=true', () => {
      const url = 'https://gitlab.com/test?labels%5B%5D=foo&labels%5B%5D=bar';

      expect(urlUtils.setUrlParams({ labels: [] }, url, false, true)).toEqual(
        'https://gitlab.com/test',
      );
    });

    it('decodes URI when decodeURI=true', () => {
      const url = 'https://gitlab.com/test';

      expect(urlUtils.setUrlParams({ labels: ['foo', 'bar'] }, url, false, true, true)).toEqual(
        'https://gitlab.com/test?labels[]=foo&labels[]=bar',
      );
    });

    it('removes all existing URL params and sets a new param when cleanParams=true', () => {
      const url = 'https://gitlab.com/test?group_id=gitlab-org&project_id=my-project';

      expect(urlUtils.setUrlParams({ foo: 'bar' }, url, true)).toEqual(
        'https://gitlab.com/test?foo=bar',
      );
    });
  });

  describe('getHTTPProtocol', () => {
    const httpProtocol = 'http:';
    const httpsProtocol = 'https:';

    it.each([[httpProtocol], [httpsProtocol]])(
      'when no url passed, returns correct protocol for %i from window location',
      (protocol) => {
        setWindowLocation({
          protocol,
        });
        expect(urlUtils.getHTTPProtocol()).toBe(protocol.slice(0, -1));
      },
    );

    it.each`
      url                      | expectation
      ${'not-a-url'}           | ${undefined}
      ${'wss://example.com'}   | ${'wss'}
      ${'https://foo.bar'}     | ${'https'}
      ${'http://foo.bar'}      | ${'http'}
      ${'http://foo.bar:8080'} | ${'http'}
    `('returns correct protocol for $url', ({ url, expectation }) => {
      expect(urlUtils.getHTTPProtocol(url)).toBe(expectation);
    });
  });

  describe('stripPathTail', () => {
    it.each`
      path                     | expected
      ${''}                    | ${''}
      ${'index.html'}          | ${''}
      ${'/'}                   | ${'/'}
      ${'/foo/bar'}            | ${'/foo/'}
      ${'/foo/bar/'}           | ${'/foo/bar/'}
      ${'/foo/bar/index.html'} | ${'/foo/bar/'}
    `('strips the filename from $path => $expected', ({ path, expected }) => {
      expect(urlUtils.stripPathTail(path)).toBe(expected);
    });
  });

  describe('getURLOrigin', () => {
    it('when no url passed, returns correct origin from window location', () => {
      const origin = 'https://foo.bar';

      setWindowLocation({ origin });
      expect(urlUtils.getURLOrigin()).toBe(origin);
    });

    it.each`
      url                          | expectation
      ${'not-a-url'}               | ${null}
      ${'wss://example.com'}       | ${'wss://example.com'}
      ${'https://foo.bar/foo/bar'} | ${'https://foo.bar'}
    `('returns correct origin for $url', ({ url, expectation }) => {
      expect(urlUtils.getURLOrigin(url)).toBe(expectation);
    });
  });

  describe('encodeSaferUrl', () => {
    it.each`
      character | input                 | output
      ${' '}    | ${'/url/hello 1.jpg'} | ${'/url/hello%201.jpg'}
      ${'#'}    | ${'/url/hello#1.jpg'} | ${'/url/hello%231.jpg'}
      ${'!'}    | ${'/url/hello!.jpg'}  | ${'/url/hello%21.jpg'}
      ${'~'}    | ${'/url/hello~.jpg'}  | ${'/url/hello%7E.jpg'}
      ${'*'}    | ${'/url/hello*.jpg'}  | ${'/url/hello%2A.jpg'}
      ${"'"}    | ${"/url/hello'.jpg"}  | ${'/url/hello%27.jpg'}
      ${'('}    | ${'/url/hello(.jpg'}  | ${'/url/hello%28.jpg'}
      ${')'}    | ${'/url/hello).jpg'}  | ${'/url/hello%29.jpg'}
      ${'?'}    | ${'/url/hello?.jpg'}  | ${'/url/hello%3F.jpg'}
      ${'='}    | ${'/url/hello=.jpg'}  | ${'/url/hello%3D.jpg'}
      ${'+'}    | ${'/url/hello+.jpg'}  | ${'/url/hello%2B.jpg'}
      ${'&'}    | ${'/url/hello&.jpg'}  | ${'/url/hello%26.jpg'}
    `(
      'properly escapes `$character` characters while retaining the integrity of the URL',
      ({ input, output }) => {
        expect(urlUtils.encodeSaferUrl(input)).toBe(output);
      },
    );

    it.each`
      character | input
      ${'/, .'} | ${'/url/hello.png'}
      ${'\\d'}  | ${'/url/hello123.png'}
      ${'-'}    | ${'/url/hello-123.png'}
      ${'_'}    | ${'/url/hello_123.png'}
    `('makes no changes to unproblematic characters ($character)', ({ input }) => {
      expect(urlUtils.encodeSaferUrl(input)).toBe(input);
    });
  });

  describe('isSameOriginUrl', () => {
    // eslint-disable-next-line no-script-url
    const javascriptUrl = 'javascript:alert(1)';

    beforeEach(() => {
      setWindowLocation({ origin: TEST_HOST });
    });

    it.each`
      url                                | expected
      ${TEST_HOST}                       | ${true}
      ${`${TEST_HOST}/a/path`}           | ${true}
      ${'//test.host/no-protocol'}       | ${true}
      ${'/a/root/relative/path'}         | ${true}
      ${'a/relative/path'}               | ${true}
      ${'#hash'}                         | ${true}
      ${'?param=foo'}                    | ${true}
      ${''}                              | ${true}
      ${'../../../'}                     | ${true}
      ${`${TEST_HOST}:8080/wrong-port`}  | ${false}
      ${'ws://test.host/wrong-protocol'} | ${false}
      ${'http://phishing.test'}          | ${false}
      ${'//phishing.test'}               | ${false}
      ${'//invalid:url'}                 | ${false}
      ${javascriptUrl}                   | ${false}
      ${'data:,Hello%2C%20World%21'}     | ${false}
      ${null}                            | ${false}
      ${undefined}                       | ${false}
    `('returns $expected given $url', ({ url, expected }) => {
      expect(urlUtils.isSameOriginUrl(url)).toBe(expected);
    });
  });
});
