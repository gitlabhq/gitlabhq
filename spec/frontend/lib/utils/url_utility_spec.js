import * as urlUtils from '~/lib/utils/url_utility';

const setWindowLocation = value => {
  Object.defineProperty(window, 'location', {
    writable: true,
    value,
  });
};

describe('URL utility', () => {
  describe('webIDEUrl', () => {
    afterEach(() => {
      gon.relative_url_root = '';
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
    it('adds w', () => {
      expect(urlUtils.mergeUrlParams({ w: 1 }, '#frag')).toBe('?w=1#frag');
      expect(urlUtils.mergeUrlParams({ w: 1 }, '/path#frag')).toBe('/path?w=1#frag');
      expect(urlUtils.mergeUrlParams({ w: 1 }, 'https://host/path')).toBe('https://host/path?w=1');
      expect(urlUtils.mergeUrlParams({ w: 1 }, 'https://host/path#frag')).toBe(
        'https://host/path?w=1#frag',
      );

      expect(urlUtils.mergeUrlParams({ w: 1 }, 'https://h/p?k1=v1#frag')).toBe(
        'https://h/p?k1=v1&w=1#frag',
      );
    });

    it('updates w', () => {
      expect(urlUtils.mergeUrlParams({ w: 1 }, '?k1=v1&w=0#frag')).toBe('?k1=v1&w=1#frag');
    });

    it('adds multiple params', () => {
      expect(urlUtils.mergeUrlParams({ a: 1, b: 2, c: 3 }, '#frag')).toBe('?a=1&b=2&c=3#frag');
    });

    it('adds and updates encoded params', () => {
      expect(urlUtils.mergeUrlParams({ a: '&', q: '?' }, '?a=%23#frag')).toBe('?a=%26&q=%3F#frag');
    });

    it('treats "+" as "%20"', () => {
      expect(urlUtils.mergeUrlParams({ ref: 'bogus' }, '?a=lorem+ipsum&ref=charlie')).toBe(
        '?a=lorem%20ipsum&ref=bogus',
      );
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
    it('should return true when the given string exists in the URL hash', () => {
      setWindowLocation({
        href: 'https://gitlab.com/gitlab-org/gitlab-test/issues/1#note_1',
      });

      expect(urlUtils.doesHashExistInUrl('note_')).toBe(true);
    });

    it('should return false when the given string does not exist in the URL hash', () => {
      setWindowLocation({
        href: 'https://gitlab.com/gitlab-org/gitlab-test/issues/1#note_1',
      });

      expect(urlUtils.doesHashExistInUrl('doesnotexist')).toBe(false);
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

  describe('isAbsoluteOrRootRelative', () => {
    const validUrls = ['https://gitlab.com/', 'http://gitlab.com/', '/users/sign_in'];

    const invalidUrls = [' https://gitlab.com/', './file/path', 'notanurl', '<a></a>'];

    it.each(validUrls)(`returns true for %s`, url => {
      expect(urlUtils.isAbsoluteOrRootRelative(url)).toBe(true);
    });

    it.each(invalidUrls)(`returns false for %s`, url => {
      expect(urlUtils.isAbsoluteOrRootRelative(url)).toBe(false);
    });
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
      it.each(safeUrls)('returns true for %s', url => {
        expect(urlUtils.isSafeURL(url)).toBe(true);
      });

      it.each(unsafeUrls)('returns false for %s', url => {
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

  describe('queryToObject', () => {
    it('converts search query into an object', () => {
      const searchQuery = '?one=1&two=2';

      expect(urlUtils.queryToObject(searchQuery)).toEqual({ one: '1', two: '2' });
    });
  });

  describe('objectToQuery', () => {
    it('converts search query object back into a search query', () => {
      const searchQueryObject = { one: '1', two: '2' };

      expect(urlUtils.objectToQuery(searchQueryObject)).toEqual('one=1&two=2');
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

  describe('escapeFileUrl', () => {
    it('encodes URL excluding the slashes', () => {
      expect(urlUtils.escapeFileUrl('/foo-bar/file.md')).toBe('/foo-bar/file.md');
      expect(urlUtils.escapeFileUrl('foo bar/file.md')).toBe('foo%20bar/file.md');
      expect(urlUtils.escapeFileUrl('foo/bar/file.md')).toBe('foo/bar/file.md');
    });
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

  it('handles arrays properly', () => {
    const url = 'https://gitlab.com/test';

    expect(urlUtils.setUrlParams({ label_name: ['foo', 'bar'] }, url)).toEqual(
      'https://gitlab.com/test?label_name=foo&label_name=bar',
    );
  });

  it('removes all existing URL params and sets a new param when cleanParams=true', () => {
    const url = 'https://gitlab.com/test?group_id=gitlab-org&project_id=my-project';

    expect(urlUtils.setUrlParams({ foo: 'bar' }, url, true)).toEqual(
      'https://gitlab.com/test?foo=bar',
    );
  });
});
