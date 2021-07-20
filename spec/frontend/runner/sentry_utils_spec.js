import * as Sentry from '@sentry/browser';
import { captureException } from '~/runner/sentry_utils';

jest.mock('@sentry/browser');

describe('~/runner/sentry_utils', () => {
  let mockSetTag;

  beforeEach(async () => {
    mockSetTag = jest.fn();

    Sentry.withScope.mockImplementation((fn) => {
      const scope = { setTag: mockSetTag };
      fn(scope);
    });
  });

  describe('captureException', () => {
    const mockError = new Error('Something went wrong!');

    it('error is reported to sentry', () => {
      captureException({ error: mockError });

      expect(Sentry.withScope).toHaveBeenCalled();
      expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
    });

    it('error is reported to sentry with a component name', () => {
      const mockComponentName = 'MyComponent';

      captureException({ error: mockError, component: mockComponentName });

      expect(Sentry.withScope).toHaveBeenCalled();
      expect(Sentry.captureException).toHaveBeenCalledWith(mockError);

      expect(mockSetTag).toHaveBeenCalledWith('vue_component', mockComponentName);
    });
  });
});
