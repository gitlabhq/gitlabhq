/**
 * Integration tests for mermaid module initialization
 * Verifies that the module properly integrates path validation
 * with webpack public path initialization
 */
/* eslint-disable global-require */

jest.mock('mermaid', () => ({
  mermaidAPI: {
    render: jest.fn(),
  },
  initialize: jest.fn(),
}));

jest.mock('dompurify', () => ({
  sanitize: jest.fn(),
  addHook: jest.fn(),
}));

jest.mock('~/lib/utils/webpack');

describe('mermaid module - path validation integration', () => {
  beforeEach(() => {
    jest.resetModules();
    delete window.gon;
  });

  it('should initialize webpack and set window.gon when path is valid', () => {
    const urlUtility = require('~/lib/utils/url_utility');
    jest.spyOn(urlUtility, 'getParameterByName').mockReturnValue('/gitlab');

    const { resetServiceWorkersPublicPath } = require('~/lib/utils/webpack');
    require('~/lib/mermaid');

    expect(resetServiceWorkersPublicPath).toHaveBeenCalled();
    expect(window.gon).toEqual({ relative_url_root: '/gitlab' });
  });

  it('should not initialize webpack or set window.gon when path is invalid', () => {
    const urlUtility = require('~/lib/utils/url_utility');
    jest.spyOn(urlUtility, 'getParameterByName').mockReturnValue('//attacker.com');

    const { resetServiceWorkersPublicPath } = require('~/lib/utils/webpack');
    require('~/lib/mermaid');

    expect(resetServiceWorkersPublicPath).not.toHaveBeenCalled();
    expect(window.gon).toBeUndefined();
  });

  it('should trim whitespace from valid paths', () => {
    const urlUtility = require('~/lib/utils/url_utility');
    jest.spyOn(urlUtility, 'getParameterByName').mockReturnValue('  /gitlab  ');

    const { resetServiceWorkersPublicPath } = require('~/lib/utils/webpack');
    require('~/lib/mermaid');

    expect(resetServiceWorkersPublicPath).toHaveBeenCalled();
    expect(window.gon).toEqual({ relative_url_root: '/gitlab' });
  });
});
