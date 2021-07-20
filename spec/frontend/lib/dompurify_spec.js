import { sanitize } from '~/lib/dompurify';

// GDK
const rootGon = {
  sprite_file_icons: '/assets/icons-123a.svg',
  sprite_icons: '/assets/icons-456b.svg',
};

// Production
const absoluteGon = {
  sprite_file_icons: `${window.location.protocol}//${window.location.hostname}/assets/icons-123a.svg`,
  sprite_icons: `${window.location.protocol}//${window.location.hostname}/assets/icons-456b.svg`,
};

const expectedSanitized = '<svg><use></use></svg>';

const safeUrls = {
  root: Object.values(rootGon).map((url) => `${url}#ellipsis_h`),
  absolute: Object.values(absoluteGon).map((url) => `${url}#ellipsis_h`),
};

const unsafeUrls = [
  '/an/evil/url',
  '../../../evil/url',
  'https://evil.url/assets/icons-123a.svg',
  'https://evil.url/assets/icons-456b.svg',
  `https://evil.url/${rootGon.sprite_icons}`,
  `https://evil.url/${rootGon.sprite_file_icons}`,
  `https://evil.url/${absoluteGon.sprite_icons}`,
  `https://evil.url/${absoluteGon.sprite_file_icons}`,
];

const forbiddenDataAttrs = ['data-remote', 'data-url', 'data-type', 'data-method'];
const acceptedDataAttrs = ['data-random', 'data-custom'];

describe('~/lib/dompurify', () => {
  let originalGon;

  it('uses local configuration when given', () => {
    // As dompurify uses a "Persistent Configuration", it might
    // ignore config, this check verifies we respect
    // https://github.com/cure53/DOMPurify#persistent-configuration
    expect(sanitize('<br>', { ALLOWED_TAGS: [] })).toBe('');
    expect(sanitize('<strong></strong>', { ALLOWED_TAGS: [] })).toBe('');
  });

  describe.each`
    type          | gon
    ${'root'}     | ${rootGon}
    ${'absolute'} | ${absoluteGon}
  `('when gon contains $type icon urls', ({ type, gon }) => {
    beforeAll(() => {
      originalGon = window.gon;
      window.gon = gon;
    });

    afterAll(() => {
      window.gon = originalGon;
    });

    it('allows no href attrs', () => {
      const htmlHref = `<svg><use></use></svg>`;
      expect(sanitize(htmlHref)).toBe(htmlHref);
    });

    it.each(safeUrls[type])('allows safe URL %s', (url) => {
      const htmlHref = `<svg><use href="${url}"></use></svg>`;
      expect(sanitize(htmlHref)).toBe(htmlHref);

      const htmlXlink = `<svg><use xlink:href="${url}"></use></svg>`;
      expect(sanitize(htmlXlink)).toBe(htmlXlink);
    });

    it.each(unsafeUrls)('sanitizes unsafe URL %s', (url) => {
      const htmlHref = `<svg><use href="${url}"></use></svg>`;
      const htmlXlink = `<svg><use xlink:href="${url}"></use></svg>`;

      expect(sanitize(htmlHref)).toBe(expectedSanitized);
      expect(sanitize(htmlXlink)).toBe(expectedSanitized);
    });
  });

  describe('when gon does not contain icon urls', () => {
    beforeAll(() => {
      originalGon = window.gon;
      window.gon = {};
    });

    afterAll(() => {
      window.gon = originalGon;
    });

    it.each([...safeUrls.root, ...safeUrls.absolute, ...unsafeUrls])('sanitizes URL %s', (url) => {
      const htmlHref = `<svg><use href="${url}"></use></svg>`;
      const htmlXlink = `<svg><use xlink:href="${url}"></use></svg>`;

      expect(sanitize(htmlHref)).toBe(expectedSanitized);
      expect(sanitize(htmlXlink)).toBe(expectedSanitized);
    });
  });

  describe('handles data attributes correctly', () => {
    it.each(forbiddenDataAttrs)('removes %s attributes', (attr) => {
      const htmlHref = `<a ${attr}="true">hello</a>`;
      expect(sanitize(htmlHref)).toBe('<a>hello</a>');
    });

    it.each(acceptedDataAttrs)('does not remove %s attributes', (attr) => {
      const attrWithValue = `${attr}="true"`;
      const htmlHref = `<a ${attrWithValue}>hello</a>`;
      expect(sanitize(htmlHref)).toBe(`<a ${attrWithValue}>hello</a>`);
    });
  });
});
