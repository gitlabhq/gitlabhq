import Tracking from '~/tracking';
import FormErrorTracker from '~/pages/shared/form_error_tracker';

describe('FormErrorTracker', () => {
  const id = 'new_user_username';
  const message = 'please_match_the_format_requested.';
  const trackAction = 'free_registration';

  describe('trackErrorOnChange', () => {
    it('tracks error', () => {
      jest.spyOn(Tracking, 'event');

      FormErrorTracker.trackErrorOnChange({
        target: {
          id,
          validationMessage: message,
          value: '1',
          checkValidity: () => false,
          dataset: { trackActionForErrors: trackAction },
        },
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, `track_${trackAction}_error`, {
        label: `${id}_${message}`,
      });
    });
  });

  describe('trackErrorOnEmptyField', () => {
    it('tracks error when input filed is empty', () => {
      jest.spyOn(Tracking, 'event');

      FormErrorTracker.trackErrorOnEmptyField({
        target: {
          id,
          validationMessage: message,
          value: '',
          dataset: { trackActionForErrors: trackAction },
        },
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, `track_${trackAction}_error`, {
        label: `${id}_${message}`,
      });
    });

    it('tracks error when radio button is unchecked', () => {
      jest.spyOn(Tracking, 'event');

      FormErrorTracker.trackErrorOnEmptyField({
        target: {
          id,
          validationMessage: message,
          value: true,
          checked: false,
          dataset: { trackActionForErrors: trackAction },
        },
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, `track_${trackAction}_error`, {
        label: `${id}_${message}`,
      });
    });
  });

  describe('errorMessage', () => {
    it('returns input validation message converted to snake case', () => {
      expect(
        FormErrorTracker.errorMessage({
          id,
          validationMessage: 'Please match the format requested.',
        }),
      ).toBe(message);
    });

    describe('when email field', () => {
      it('returns email validation message', () => {
        expect(FormErrorTracker.errorMessage({ id: 'new_user_email' })).toBe(
          'invalid_email_address',
        );
      });
    });

    describe('when password field', () => {
      it('returns password validation message', () => {
        expect(FormErrorTracker.errorMessage({ id: 'new_user_password' })).toBe(
          'password_is_too_short',
        );
      });
    });
  });

  describe('inputErrorMessage', () => {
    it('returns input validation message converted to snake case', () => {
      expect(
        FormErrorTracker.inputErrorMessage({
          validationMessage: 'Please match the format requested.',
        }),
      ).toBe(message);
    });
  });

  describe('action', () => {
    it('returns action', () => {
      expect(
        FormErrorTracker.action({
          dataset: { trackActionForErrors: trackAction },
        }),
      ).toBe(`track_${trackAction}_error`);
    });
  });

  describe('label', () => {
    it('returns label', () => {
      expect(FormErrorTracker.label({ id }, message)).toBe(`${id}_${message}`);
    });

    it('returns label containing form-group label for radio buttons', () => {
      const mockFormGroup = document.createElement('div');
      mockFormGroup.className = 'form-group';
      mockFormGroup.innerHTML = '<label>groupLabel</label><input type="radio" id="mock-radio">';
      const mockRadio = mockFormGroup.querySelector('#mock-radio');

      expect(FormErrorTracker.label(mockRadio, message)).toBe('missing_group_label');
    });
  });
});
