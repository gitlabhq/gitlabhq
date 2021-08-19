import setWindowLocation from './set_window_location_helper';
import { TEST_HOST } from './test_constants';

describe('helpers/set_window_location_helper', () => {
  const originalLocation = window.location.href;

  beforeEach(() => {
    setWindowLocation(originalLocation);
  });

  describe('setWindowLocation', () => {
    describe('given a complete URL', () => {
      it.each`
        url                                    | property      | value
        ${'https://gitlab.com#foo'}            | ${'hash'}     | ${'#foo'}
        ${'http://gitlab.com'}                 | ${'host'}     | ${'gitlab.com'}
        ${'http://gitlab.org'}                 | ${'hostname'} | ${'gitlab.org'}
        ${'http://gitlab.org/foo#bar'}         | ${'href'}     | ${'http://gitlab.org/foo#bar'}
        ${'http://gitlab.com'}                 | ${'origin'}   | ${'http://gitlab.com'}
        ${'http://gitlab.com/foo/bar/baz'}     | ${'pathname'} | ${'/foo/bar/baz'}
        ${'https://gitlab.com'}                | ${'protocol'} | ${'https:'}
        ${'ftp://gitlab.com#foo'}              | ${'protocol'} | ${'ftp:'}
        ${'http://gitlab.com:8080'}            | ${'port'}     | ${'8080'}
        ${'http://gitlab.com?foo=bar&bar=foo'} | ${'search'}   | ${'?foo=bar&bar=foo'}
      `(
        'sets "window.location.$property" to be "$value" when called with: "$url"',
        ({ url, property, value }) => {
          expect(window.location.href).toBe(originalLocation);

          setWindowLocation(url);

          expect(window.location[property]).toBe(value);
        },
      );
    });

    describe('given a partial URL', () => {
      it.each`
        partialURL            | href
        ${'//foo.test:3000/'} | ${'http://foo.test:3000/'}
        ${'/foo/bar'}         | ${`${originalLocation}foo/bar`}
        ${'foo/bar'}          | ${`${originalLocation}foo/bar`}
        ${'?foo=bar'}         | ${`${originalLocation}?foo=bar`}
        ${'#a-thing'}         | ${`${originalLocation}#a-thing`}
      `('$partialURL sets location.href to $href', ({ partialURL, href }) => {
        expect(window.location.href).toBe(originalLocation);

        setWindowLocation(partialURL);

        expect(window.location.href).toBe(href);
      });
    });

    describe('relative path', () => {
      describe.each`
        initialHref                    | path        | newHref
        ${'https://gdk.test/foo/bar'}  | ${'/qux'}   | ${'https://gdk.test/qux'}
        ${'https://gdk.test/foo/bar/'} | ${'/qux'}   | ${'https://gdk.test/qux'}
        ${'https://gdk.test/foo/bar'}  | ${'qux'}    | ${'https://gdk.test/foo/qux'}
        ${'https://gdk.test/foo/bar/'} | ${'qux'}    | ${'https://gdk.test/foo/bar/qux'}
        ${'https://gdk.test/foo/bar'}  | ${'../qux'} | ${'https://gdk.test/qux'}
        ${'https://gdk.test/foo/bar/'} | ${'../qux'} | ${'https://gdk.test/foo/qux'}
      `('when location is $initialHref', ({ initialHref, path, newHref }) => {
        beforeEach(() => {
          setWindowLocation(initialHref);
        });

        it(`${path} sets window.location.href to ${newHref}`, () => {
          expect(window.location.href).toBe(initialHref);

          setWindowLocation(path);

          expect(window.location.href).toBe(newHref);
        });
      });
    });

    it.each([null, 1, undefined, false, 'https://', 'https:', { foo: 1 }, []])(
      'throws an error when called with an invalid url: "%s"',
      (invalidUrl) => {
        expect(() => setWindowLocation(invalidUrl)).toThrow();
        expect(window.location.href).toBe(originalLocation);
      },
    );

    describe('affects links', () => {
      it.each`
        url                                 | hrefAttr          | expectedHref
        ${'http://gitlab.com/'}             | ${'foo'}          | ${'http://gitlab.com/foo'}
        ${'http://gitlab.com/bar/'}         | ${'foo'}          | ${'http://gitlab.com/bar/foo'}
        ${'http://gitlab.com/bar/'}         | ${'/foo'}         | ${'http://gitlab.com/foo'}
        ${'http://gdk.test:3000/?foo=bar'}  | ${'?qux=1'}       | ${'http://gdk.test:3000/?qux=1'}
        ${'https://gdk.test:3000/?foo=bar'} | ${'//other.test'} | ${'https://other.test/'}
      `(
        'given $url, <a href="$hrefAttr"> points to $expectedHref',
        ({ url, hrefAttr, expectedHref }) => {
          setWindowLocation(url);

          const link = document.createElement('a');
          link.setAttribute('href', hrefAttr);

          expect(link.href).toBe(expectedHref);
        },
      );
    });
  });

  // This set of tests relies on Jest executing tests in source order, which is
  // at the time of writing the only order they will execute, by design.
  // See https://github.com/facebook/jest/issues/4386 for more details.
  describe('window.location resetting by global beforeEach', () => {
    const overridden = 'https://gdk.test:1234/';
    const initial = `${TEST_HOST}/`;

    it('works before an override', () => {
      expect(window.location.href).toBe(initial);
    });

    describe('overriding', () => {
      beforeEach(() => {
        setWindowLocation(overridden);
      });

      it('works', () => {
        expect(window.location.href).toBe(overridden);
      });
    });

    it('works after an override', () => {
      expect(window.location.href).toBe(initial);
    });
  });
});
