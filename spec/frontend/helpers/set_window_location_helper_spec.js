import setWindowLocation from './set_window_location_helper';

describe('setWindowLocation', () => {
  const originalLocation = window.location;

  afterEach(() => {
    window.location = originalLocation;
  });

  it.each`
    url                                    | property      | value
    ${'https://gitlab.com#foo'}            | ${'hash'}     | ${'#foo'}
    ${'http://gitlab.com'}                 | ${'host'}     | ${'gitlab.com'}
    ${'http://gitlab.org'}                 | ${'hostname'} | ${'gitlab.org'}
    ${'http://gitlab.org/foo#bar'}         | ${'href'}     | ${'http://gitlab.org/foo#bar'}
    ${'http://gitlab.com'}                 | ${'origin'}   | ${'http://gitlab.com'}
    ${'http://gitlab.com/foo/bar/baz'}     | ${'pathname'} | ${'/foo/bar/baz'}
    ${'https://gitlab.com'}                | ${'protocol'} | ${'https:'}
    ${'http://gitlab.com#foo'}             | ${'protocol'} | ${'http:'}
    ${'http://gitlab.com:8080'}            | ${'port'}     | ${'8080'}
    ${'http://gitlab.com?foo=bar&bar=foo'} | ${'search'}   | ${'?foo=bar&bar=foo'}
  `(
    'sets "window.location.$property" to be "$value" when called with: "$url"',
    ({ url, property, value }) => {
      expect(window.location).toBe(originalLocation);

      setWindowLocation(url);

      expect(window.location[property]).toBe(value);
    },
  );

  it.each([null, 1, undefined, false, '', 'gitlab.com'])(
    'throws an error when called with an invalid url: "%s"',
    (invalidUrl) => {
      expect(() => setWindowLocation(invalidUrl)).toThrow(/Invalid URL/);
      expect(window.location).toBe(originalLocation);
    },
  );
});
