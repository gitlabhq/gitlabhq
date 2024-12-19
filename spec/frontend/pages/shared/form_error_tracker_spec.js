import Tracking from '~/tracking';
import FormErrorTracker from '~/pages/shared/form_error_tracker';

describe('FormErrorTracker', () => {
  const id = 'new_user_username';
  const trackAction = 'free_registration';
  const validationMessage = 'Please match the format requested.';
  const convertedValidationMessage = 'please_match_the_format_requested.';

  describe('trackErrorOnChange', () => {
    it('tracks error', () => {
      jest.spyOn(Tracking, 'event');

      FormErrorTracker.trackErrorOnChange({
        target: {
          id,
          value: '1',
          checkValidity: () => false,
          dataset: { trackActionForErrors: trackAction },
        },
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, `track_${trackAction}_error`, {
        label: `${id}_is_invalid`,
      });
    });
  });

  describe('trackErrorOnEmptyField', () => {
    it('tracks error when input field is empty', () => {
      jest.spyOn(Tracking, 'event');

      FormErrorTracker.trackErrorOnEmptyField({
        target: {
          id,
          value: '',
          dataset: { trackActionForErrors: trackAction },
        },
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, `track_${trackAction}_error`, {
        label: `${id}_is_required`,
      });
    });

    it('tracks error when radio button is unchecked', () => {
      const mockFormGroup = document.createElement('div');

      mockFormGroup.className = 'form-group';
      mockFormGroup.innerHTML = `
        <label for="group_label">groupLabel</label>
        <input type="radio" id="mock-radio" data-track-action-for-errors="${trackAction}">
      `;

      const mockRadio = mockFormGroup.querySelector('#mock-radio');

      jest.spyOn(Tracking, 'event');
      FormErrorTracker.trackErrorOnEmptyField({ target: mockRadio });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, `track_${trackAction}_error`, {
        label: 'missing_group_label',
      });
    });

    it('does not track an error when input field is not empty', () => {
      jest.spyOn(Tracking, 'event');

      FormErrorTracker.trackErrorOnEmptyField({
        target: {
          id,
          value: 'value',
          dataset: { trackActionForErrors: trackAction },
        },
      });

      expect(Tracking.event).not.toHaveBeenCalled();
    });
  });

  describe('errorMessage', () => {
    it.each`
      elementId                | result
      ${'new_user_first_name'} | ${'is_invalid'}
      ${'new_user_last_name'}  | ${'is_invalid'}
      ${id}                    | ${'is_invalid'}
      ${'new_user_email'}      | ${'is_invalid'}
      ${'new_user_password'}   | ${'is_invalid'}
      ${'company_name'}        | ${'is_invalid'}
      ${'company_size'}        | ${convertedValidationMessage}
    `('returns input validation message for $elementId', ({ elementId, result }) => {
      expect(FormErrorTracker.errorMessage({ validationMessage, id: elementId })).toBe(result);
    });
  });

  describe('inputErrorMessage', () => {
    it('returns input validation message converted to snake case', () => {
      expect(FormErrorTracker.inputErrorMessage({ validationMessage })).toBe(
        convertedValidationMessage,
      );
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
      expect(FormErrorTracker.label({ id }, convertedValidationMessage)).toBe(
        `${id}_${convertedValidationMessage}`,
      );
    });

    it('returns label containing form-group label for radio buttons', () => {
      const mockFormGroup = document.createElement('div');
      mockFormGroup.className = 'form-group';
      mockFormGroup.innerHTML =
        '<label for="group_label">groupLabel</label><input type="radio" id="mock-radio">';
      const mockRadio = mockFormGroup.querySelector('#mock-radio');

      expect(FormErrorTracker.label(mockRadio, convertedValidationMessage)).toBe(
        'missing_group_label',
      );
    });
  });
});
