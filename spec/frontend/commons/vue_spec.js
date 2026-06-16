import * as Sentry from '~/sentry/sentry_browser_wrapper';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('commons/vue, Vue.config.errorHandler installation', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  it('does not install a global errorHandler outside production', () => {
    let installedHandler;
    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      require('~/commons/vue');
      // eslint-disable-next-line global-require
      installedHandler = require('vue').default.config.errorHandler;
    });

    // eslint-disable-next-line jest/no-restricted-matchers
    expect(installedHandler).toBeFalsy();
    expect(Sentry.captureException).not.toHaveBeenCalled();
  });

  it('forwards real Vue render errors to Sentry in production', () => {
    jest.replaceProperty(process.env, 'NODE_ENV', 'production');

    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      require('~/commons/vue');
      // eslint-disable-next-line global-require
      const Vue = require('vue').default;

      new Vue({
        name: 'ExplodingComponent',
        // eslint-disable-next-line vue/require-render-return
        render() {
          throw new Error('boom');
        },
      }).$mount(document.createElement('div'));
    });

    expect(Sentry.captureException).toHaveBeenCalledTimes(1);
    expect(Sentry.captureException).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'boom' }),
      {
        tags: { vue_error: 'true', vue_info: expect.any(String) },
        extra: { vue_component: 'ExplodingComponent' },
      },
    );
  });
});
