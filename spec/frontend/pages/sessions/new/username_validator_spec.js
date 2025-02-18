import UsernameValidator from '~/pages/sessions/new/username_validator';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import Tracking from '~/tracking';
import { createAlert } from '~/alert';

jest.mock('~/alert');
jest.mock('~/tracking');

describe('UsernameValidator', () => {
  let input;

  beforeEach(() => {
    setHTMLFixture(`
      <div class="container">
        <input id="username" class="js-validate-username" data-track-action-for-errors="username" type="text" />
        <span class="validation-success hide">Success</span>
        <span class="validation-pending hide">Checking...</span>
        <span class="validation-error hide">Username taken</span>
      </div>
    `);

    input = document.querySelector('.js-validate-username');
    // eslint-disable-next-line no-new
    new UsernameValidator({ container: '.container' });
    input.value = 'testuser';
  });

  afterEach(() => {
    resetHTMLFixture();
    jest.resetAllMocks();
  });

  describe('validateUsernameInput', () => {
    it('shows pending message', () => {
      jest.spyOn(axios, 'get').mockResolvedValue({ data: {} });
      input.dispatchEvent(new Event('input'));
      expect(document.querySelector('.validation-pending').classList.contains('hide')).toBe(false);
    });

    it('shows success message and adds correct css class to input', async () => {
      jest.spyOn(axios, 'get').mockResolvedValue({ data: { exists: false } });
      input.dispatchEvent(new Event('input'));

      await waitForPromises();

      expect(input.classList.contains('gl-field-success-outline')).toBe(true);
      expect(document.querySelector('.validation-success').classList.contains('hide')).toBe(false);
    });

    it('shows error message, adds correct css class to input and triggers tracking when username is taken', async () => {
      jest.spyOn(axios, 'get').mockResolvedValue({ data: { exists: true } });
      input.dispatchEvent(new Event('input'));

      await waitForPromises();

      expect(input.classList.contains('gl-field-error-outline')).toBe(true);
      expect(document.querySelector('.validation-error').classList.contains('hide')).toBe(false);
      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'track_username_error', {
        label: 'username_is_taken',
      });
    });

    it('creates alert when axios request fails', async () => {
      jest.spyOn(axios, 'get').mockRejectedValue();
      input.dispatchEvent(new Event('input'));

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while validating username',
      });
    });
  });
});
