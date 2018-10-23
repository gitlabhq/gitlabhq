/* eslint-disable no-script-url */
import isSafeURL from 'ee/vue_shared/components/is_safe_url';

describe('isSafeUrl', () => {
  describe('with URL constructor support', () => {
    it('returns true for absolute http(s) urls', () => {
      expect(isSafeURL('http://example.org')).toBe(true);
      expect(isSafeURL('http://example.org:8080')).toBe(true);
      expect(isSafeURL('https://example.org')).toBe(true);
      expect(isSafeURL('https://example.org:8080')).toBe(true);
      expect(isSafeURL('https://192.168.1.1')).toBe(true);
    });

    it('returns false for relative urls', () => {
      expect(isSafeURL('./relative/link')).toBe(false);
      expect(isSafeURL('/relative/link')).toBe(false);
      expect(isSafeURL('../relative/link')).toBe(false);
    });

    it('returns false for http(s) urls without host', () => {
      expect(isSafeURL('http://')).toBe(false);
      expect(isSafeURL('https://')).toBe(false);
      expect(isSafeURL('https:https:https:')).toBe(false);
    });

    it('returns false for non http(s) links', () => {
      expect(isSafeURL('javascript:')).toBe(false);
      expect(isSafeURL('javascript:alert("XSS")')).toBe(false);
      expect(isSafeURL('jav\tascript:alert("XSS");')).toBe(false);
      expect(isSafeURL(' &#14;  javascript:alert("XSS");')).toBe(false);
      expect(isSafeURL('ftp://192.168.1.1')).toBe(false);
      expect(isSafeURL('file:///')).toBe(false);
      expect(isSafeURL('file:///etc/hosts')).toBe(false);
    });

    it('returns false for encoded javascript links', () => {
      expect(
        isSafeURL(
          '&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041',
        ),
      ).toBe(false);
      expect(
        isSafeURL(
          '&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;',
        ),
      ).toBe(false);
      expect(
        isSafeURL(
          '&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29',
        ),
      ).toBe(false);
      expect(
        isSafeURL(
          '\\u006A\\u0061\\u0076\\u0061\\u0073\\u0063\\u0072\\u0069\\u0070\\u0074\\u003A\\u0061\\u006C\\u0065\\u0072\\u0074\\u0028\\u0027\\u0058\\u0053\\u0053\\u0027\\u0029',
        ),
      ).toBe(false);
    });
  });

  describe('without URL constructor support', () => {
    beforeEach(() => {
      spyOn(window, 'URL').and.callFake(() => {
        throw new Error('No URL support');
      });
    });

    it('returns true for absolute http(s) urls', () => {
      expect(isSafeURL('http://example.org')).toBe(true);
      expect(isSafeURL('http://example.org:8080')).toBe(true);
      expect(isSafeURL('https://example.org')).toBe(true);
      expect(isSafeURL('https://example.org:8080')).toBe(true);
      expect(isSafeURL('https://192.168.1.1')).toBe(true);
    });

    it('returns true for relative urls', () => {
      expect(isSafeURL('./relative/link')).toBe(false);
      expect(isSafeURL('/relative/link')).toBe(false);
      expect(isSafeURL('../relative/link')).toBe(false);
    });

    it('returns false for http(s) urls without host', () => {
      expect(isSafeURL('http://')).toBe(false);
      expect(isSafeURL('https://')).toBe(false);
      expect(isSafeURL('https:https:https:')).toBe(false);
    });

    it('returns false for non http(s) links', () => {
      expect(isSafeURL('javascript:')).toBe(false);
      expect(isSafeURL('javascript:alert("XSS")')).toBe(false);
      expect(isSafeURL('jav\tascript:alert("XSS");')).toBe(false);
      expect(isSafeURL(' &#14;  javascript:alert("XSS");')).toBe(false);
      expect(isSafeURL('ftp://192.168.1.1')).toBe(false);
      expect(isSafeURL('file:///')).toBe(false);
      expect(isSafeURL('file:///etc/hosts')).toBe(false);
    });

    it('returns false for encoded javascript links', () => {
      expect(
        isSafeURL(
          '&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041',
        ),
      ).toBe(false);
      expect(
        isSafeURL(
          '&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;',
        ),
      ).toBe(false);
      expect(
        isSafeURL(
          '&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29',
        ),
      ).toBe(false);
      expect(
        isSafeURL(
          '\\u006A\\u0061\\u0076\\u0061\\u0073\\u0063\\u0072\\u0069\\u0070\\u0074\\u003A\\u0061\\u006C\\u0065\\u0072\\u0074\\u0028\\u0027\\u0058\\u0053\\u0053\\u0027\\u0029',
        ),
      ).toBe(false);
    });
  });
});
