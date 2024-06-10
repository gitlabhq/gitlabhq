import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { renderWebIdeError } from '~/ide/render_web_ide_error';
import { logError } from '~/lib/logger';
import { resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/logger');

describe('render web IDE error', () => {
  const MOCK_ERROR = new Error('error');
  const MOCK_SIGNOUT_PATH = '/signout';

  const setupFlashContainer = () => {
    const flashContainer = document.createElement('div');
    flashContainer.classList.add('flash-container');

    document.body.appendChild(flashContainer);
  };

  const findAlert = () => document.querySelector('.flash-container .gl-alert');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('with flash-container', () => {
    beforeEach(() => {
      setupFlashContainer();

      renderWebIdeError({ error: MOCK_ERROR, signOutPath: MOCK_SIGNOUT_PATH });
    });

    it('logs error to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(MOCK_ERROR);
    });

    it('logs error to console', () => {
      expect(logError).toHaveBeenCalledWith('Failed to load Web IDE', MOCK_ERROR);
    });

    it('should render alert', () => {
      expect(findAlert()).toBeInstanceOf(HTMLElement);
    });
  });

  describe('no .flash-container', () => {
    beforeEach(() => {
      renderWebIdeError({ error: MOCK_ERROR, signOutPath: MOCK_SIGNOUT_PATH });
    });

    it('does not render alert', () => {
      expect(findAlert()).toBeNull();
    });
  });
});
