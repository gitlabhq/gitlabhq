import * as Sentry from '~/sentry/sentry_browser_wrapper';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('vueErrorHandler', () => {
  it('forwards the error to Sentry with vue tags and component name', () => {
    let vueErrorHandler;
    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      ({ vueErrorHandler } = require('~/sentry/vue_error_handler'));
    });

    const err = new Error('boom');
    const vm = { $options: { name: 'MyComponent' } };

    vueErrorHandler(err, vm, 'render');

    expect(Sentry.captureException).toHaveBeenCalledTimes(1);
    expect(Sentry.captureException).toHaveBeenCalledWith(err, {
      tags: { vue_error: 'true', vue_info: 'render' },
      extra: { vue_component: 'MyComponent' },
    });
  });

  it('uses "unknown" when no component context is available', () => {
    let vueErrorHandler;
    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      ({ vueErrorHandler } = require('~/sentry/vue_error_handler'));
    });

    const err = new Error('boom');

    vueErrorHandler(err, null, 'lifecycle hook');

    expect(Sentry.captureException).toHaveBeenCalledWith(
      err,
      expect.objectContaining({
        extra: { vue_component: 'unknown' },
      }),
    );
  });
});
