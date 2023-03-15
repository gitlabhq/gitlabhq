import { sanitize, defaultConfig } from '~/lib/dompurify';

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
  'https://evil.url/assets/icons-123a.svg#test',
  'https://evil.url/assets/icons-456b.svg',
  `https://evil.url/${rootGon.sprite_icons}`,
  `https://evil.url/${rootGon.sprite_file_icons}`,
  `https://evil.url/${absoluteGon.sprite_icons}`,
  `https://evil.url/${absoluteGon.sprite_file_icons}`,
  `${rootGon.sprite_icons}/../evil/path`,
  `${rootGon.sprite_file_icons}/../../evil/path`,
  `${absoluteGon.sprite_icons}/../evil/path`,
  `${absoluteGon.sprite_file_icons}/../../https://evil.url`,
];

/* eslint-disable no-script-url */
const invalidProtocolUrls = [
  'javascript:alert(1)',
  'jAvascript:alert(1)',
  'data:text/html,<script>alert(1);</script>',
  ' javascript:',
  'javascript :',
];
/* eslint-enable no-script-url */
const validProtocolUrls = ['slack://open', 'x-devonthink-item://90909', 'x-devonthink-item:90909'];

const forbiddenDataAttrs = defaultConfig.FORBID_ATTR;
const acceptedDataAttrs = ['data-random', 'data-custom'];

describe('~/lib/dompurify', () => {
  it('uses local configuration when given', () => {
    // As dompurify uses a "Persistent Configuration", it might
    // ignore config, this check verifies we respect
    // https://github.com/cure53/DOMPurify#persistent-configuration
    expect(sanitize('<br>', { ALLOWED_TAGS: [] })).toBe('');
    expect(sanitize('<strong></strong>', { ALLOWED_TAGS: [] })).toBe('');
  });

  describe('includes default configuration', () => {
    it('with empty config', () => {
      const svgIcon = '<svg width="100"><use></use></svg>';
      expect(sanitize(svgIcon, {})).toBe(svgIcon);
    });

    it('with valid config', () => {
      expect(sanitize('<a href="#" data-remote="true"></a>', { ALLOWED_TAGS: ['a'] })).toBe(
        '<a href="#"></a>',
      );
    });
  });

  it("doesn't sanitize local references", () => {
    const htmlHref = `<svg><use href="#some-element"></use></svg>`;
    const htmlXlink = `<svg><use xlink:href="#some-element"></use></svg>`;

    expect(sanitize(htmlHref)).toBe(htmlHref);
    expect(sanitize(htmlXlink)).toBe(htmlXlink);
  });

  it("doesn't sanitize gl-emoji", () => {
    expect(sanitize('<p><gl-emoji>💯</gl-emoji></p>')).toBe('<p><gl-emoji>💯</gl-emoji></p>');
  });

  it("doesn't allow style tags", () => {
    // removes style tags
    expect(sanitize('<style>p {width:50%;}</style>')).toBe('');
    expect(sanitize('<style type="text/css">p {width:50%;}</style>')).toBe('');
    // removes mstyle tag (this can removed later by disallowing math tags)
    expect(sanitize('<math><mstyle displaystyle="true"></mstyle></math>')).toBe('<math></math>');
    // removes link tag (this is DOMPurify's default behavior)
    expect(sanitize('<link rel="stylesheet" href="styles.css">')).toBe('');
  });

  it("doesn't allow form tags", () => {
    expect(sanitize('<form>')).toBe('');
    expect(sanitize('<form method="post" action="path"></form>')).toBe('');
  });

  describe.each`
    type          | gon
    ${'root'}     | ${rootGon}
    ${'absolute'} | ${absoluteGon}
  `('when gon contains $type icon urls', ({ type, gon }) => {
    beforeEach(() => {
      window.gon = gon;
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
      window.gon = {};
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

  describe('with non-http links', () => {
    it.each(validProtocolUrls)('should allow %s', (url) => {
      const html = `<a href="${url}">internal link</a>`;
      expect(sanitize(html)).toBe(`<a href="${url}">internal link</a>`);
    });

    it.each(invalidProtocolUrls)('should not allow %s', (url) => {
      const html = `<a href="${url}">internal link</a>`;
      expect(sanitize(html)).toBe(`<a>internal link</a>`);
    });
  });

  describe('links with target attribute', () => {
    const getSanitizedNode = (html) => {
      return document.createRange().createContextualFragment(sanitize(html)).firstElementChild;
    };

    it('adds secure context', () => {
      const html = `<a href="https://example.com" target="_blank">link</a>`;
      const el = getSanitizedNode(html);

      expect(el.getAttribute('target')).toBe('_blank');
      expect(el.getAttribute('rel')).toBe('noopener noreferrer');
    });

    it('adds secure context and merge existing `rel` values', () => {
      const html = `<a href="https://example.com" target="_blank" rel="help External">link</a>`;
      const el = getSanitizedNode(html);

      expect(el.getAttribute('target')).toBe('_blank');
      expect(el.getAttribute('rel')).toBe('help external noopener noreferrer');
    });

    it('does not duplicate noopener/noreferrer `rel` values', () => {
      const html = `<a href="https://example.com" target="_blank" rel="noreferrer noopener">link</a>`;
      const el = getSanitizedNode(html);

      expect(el.getAttribute('target')).toBe('_blank');
      expect(el.getAttribute('rel')).toBe('noreferrer noopener');
    });

    it('does not update `rel` values when target is not `_blank`', () => {
      const html = `<a href="https://example.com" target="_self" rel="help">internal</a>`;
      const el = getSanitizedNode(html);

      expect(el.getAttribute('target')).toBe('_self');
      expect(el.getAttribute('rel')).toBe('help');
    });

    it('does not update `rel` values when target attribute is not present', () => {
      const html = `<a href="https://example.com">link</a>`;
      const el = getSanitizedNode(html);

      expect(el.hasAttribute('target')).toBe(false);
      expect(el.hasAttribute('rel')).toBe(false);
    });
  });
});
