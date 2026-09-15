/**
 * Integration tests for mermaid module initialization
 * Verifies that the module properly integrates path initialization
 * with webpack public path via postMessage
 */
/* eslint-disable global-require */

jest.mock('mermaid-v11', () => ({
  mermaidAPI: {
    render: jest.fn().mockResolvedValue({ svg: '<svg></svg>' }),
  },
  initialize: jest.fn(),
  registerLayoutLoaders: jest.fn(),
}));

jest.mock(
  '@mermaid-js/layout-elk',
  () => ({
    __esModule: true,
    default: [{ name: 'elk' }],
  }),
  { virtual: true },
);

jest.mock('dompurify', () => ({
  sanitize: jest.fn(),
  addHook: jest.fn(),
}));

jest.mock('~/lib/utils/webpack');

['mermaid_v11'].forEach((entrypoint) => {
  describe(`${entrypoint} module - path validation integration`, () => {
    let resetServiceWorkersPublicPath;

    beforeEach(() => {
      jest.resetModules();
      delete window.gon;

      const appDiv = document.createElement('div');
      appDiv.id = 'app';
      document.body.appendChild(appDiv);

      resetServiceWorkersPublicPath = require('~/lib/utils/webpack').resetServiceWorkersPublicPath;
    });

    afterEach(() => {
      document.getElementById('app')?.remove();
    });

    const loadMermaidAndPostMessage = (relativeRootPath, originOverride = null) => {
      require(`~/lib/${entrypoint}`);

      const origin = originOverride ?? window.location.origin;

      const event = new MessageEvent('message', {
        data: { source: 'graph TD', relativeRootPath },
        origin,
      });

      window.dispatchEvent(event);
    };

    it('should initialize webpack and set window.gon when relativeRootPath is provided', () => {
      loadMermaidAndPostMessage('/gitlab');

      expect(resetServiceWorkersPublicPath).toHaveBeenCalled();
      expect(window.gon).toEqual({ relative_url_root: '/gitlab' });
    });

    it('should not initialize webpack or set window.gon when relativeRootPath is null', () => {
      loadMermaidAndPostMessage(null);

      expect(resetServiceWorkersPublicPath).not.toHaveBeenCalled();
      expect(window.gon).toBeUndefined();
    });

    it("should not initialize webpack or set window.gon when the origin doesn't match", () => {
      loadMermaidAndPostMessage('/gitlab', 'elsewhere.example');

      expect(resetServiceWorkersPublicPath).not.toHaveBeenCalled();
      expect(window.gon).toBeUndefined();
    });

    it('registers the ELK layout loaders so `layout: elk` is honored', () => {
      const mermaid = require('mermaid-v11');
      const elkLayouts = require('@mermaid-js/layout-elk').default;

      require(`~/lib/${entrypoint}`);

      expect(mermaid.registerLayoutLoaders).toHaveBeenCalledWith(elkLayouts);
    });

    describe('link click delegation', () => {
      let postMessageSpy;

      beforeEach(() => {
        postMessageSpy = jest.spyOn(window.parent, 'postMessage').mockImplementation(() => {});
      });

      const clickInApp = (html, { type = 'click', button = 0 } = {}) => {
        require(`~/lib/${entrypoint}`);

        const appDiv = document.getElementById('app');
        appDiv.innerHTML = html;

        const target = appDiv.querySelector('[data-testid="click-target"]') || appDiv;
        const event = new MouseEvent(type, { bubbles: true, cancelable: true, button });
        target.dispatchEvent(event);

        return event;
      };

      const href = 'https://docs.gitlab.com/user/markdown/';
      const anchorHtml = (attribute = 'href') =>
        `<svg><a ${attribute}="${href}"><text data-testid="click-target">link</text></a></svg>`;

      it.each`
        description                          | attribute       | options
        ${'a click on an href anchor'}       | ${'href'}       | ${{}}
        ${'a click on an xlink:href anchor'} | ${'xlink:href'} | ${{}}
        ${'a middle click on an anchor'}     | ${'href'}       | ${{ type: 'auxclick', button: 1 }}
      `(
        'delegates $description to the parent and prevents default navigation',
        ({ attribute, options }) => {
          const event = clickInApp(anchorHtml(attribute), options);

          expect(event.defaultPrevented).toBe(true);
          expect(postMessageSpy).toHaveBeenCalledWith({ href }, window.location.origin);
        },
      );

      it('does not delegate a right click on an anchor', () => {
        const event = clickInApp(anchorHtml(), { type: 'auxclick', button: 2 });

        expect(event.defaultPrevented).toBe(false);
        expect(postMessageSpy).not.toHaveBeenCalled();
      });

      it.each`
        description                    | html                                                                | defaultPrevented
        ${'a click outside an anchor'} | ${'<svg><text data-testid="click-target">no link</text></svg>'}     | ${false}
        ${'an anchor without an href'} | ${'<svg><a><text data-testid="click-target">link</text></a></svg>'} | ${true}
      `('does not post a message for $description', ({ html, defaultPrevented }) => {
        const event = clickInApp(html);

        expect(event.defaultPrevented).toBe(defaultPrevented);
        expect(postMessageSpy).not.toHaveBeenCalled();
      });
    });
  });
});
