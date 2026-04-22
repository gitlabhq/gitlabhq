/**
 * Integration tests for mermaid module initialization
 * Verifies that the module properly integrates path initialization
 * with webpack public path via postMessage
 */
/* eslint-disable global-require */

jest.mock('mermaid', () => ({
  mermaidAPI: {
    render: jest.fn().mockResolvedValue({ svg: '<svg></svg>' }),
  },
  initialize: jest.fn(),
}));

jest.mock('mermaid-v11', () => ({
  mermaidAPI: {
    render: jest.fn().mockResolvedValue({ svg: '<svg></svg>' }),
  },
  initialize: jest.fn(),
}));

jest.mock('dompurify', () => ({
  sanitize: jest.fn(),
  addHook: jest.fn(),
}));

jest.mock('~/lib/utils/webpack');

['mermaid_v10', 'mermaid_v11'].forEach((entrypoint) => {
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
  });
});
