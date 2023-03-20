import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import LengthValidator, { isAboveMaxLength, isBelowMinLength } from '~/validators/length_validator';

describe('length_validator', () => {
  describe('isAboveMaxLength', () => {
    it('should return true if the string is longer than the maximum length', () => {
      expect(isAboveMaxLength('123456', '5')).toBe(true);
    });

    it('should return false if the string is shorter than the maximum length', () => {
      expect(isAboveMaxLength('1234', '5')).toBe(false);
    });
  });

  describe('isBelowMinLength', () => {
    it('should return true if the string is shorter than the minimum length and not empty', () => {
      expect(isBelowMinLength('1234', '5', 'false')).toBe(true);
    });

    it('should return false if the string is longer than the minimum length', () => {
      expect(isBelowMinLength('123456', '5', 'false')).toBe(false);
    });

    it('should return false if the string is empty and allowed to be empty', () => {
      expect(isBelowMinLength('', '5', 'true')).toBe(false);
    });

    it('should return true if the string is empty and not allowed to be empty', () => {
      expect(isBelowMinLength('', '5', 'false')).toBe(true);
    });
  });

  describe('LengthValidator', () => {
    let input;
    let validator;

    beforeEach(() => {
      setHTMLFixture(
        '<div class="container"><input class="js-validate-length" /><span class="gl-field-error"></span></div>',
      );
      input = document.querySelector('input');
      input.dataset.minLength = '3';
      input.dataset.maxLength = '5';
      input.dataset.minLengthMessage = 'Too short';
      input.dataset.maxLengthMessage = 'Too long';
      validator = new LengthValidator({ container: '.container' });
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('sets error message for input with value longer than max length', () => {
      input.value = '123456';
      input.dispatchEvent(new Event('input'));
      expect(validator.errorMessage).toBe('Too long');
    });

    it('sets error message for input with value shorter than min length', () => {
      input.value = '12';
      input.dispatchEvent(new Event('input'));
      expect(validator.errorMessage).toBe('Too short');
    });

    it('does not set error message for input with valid length', () => {
      input.value = '123';
      input.dispatchEvent(new Event('input'));
      expect(validator.errorMessage).toBeNull();
    });

    it('does not set error message for empty input if allowEmpty is true', () => {
      input.dataset.allowEmpty = 'true';
      input.value = '';
      input.dispatchEvent(new Event('input'));
      expect(validator.errorMessage).toBeNull();
    });

    it('sets error message for empty input if allowEmpty is false', () => {
      input.dataset.allowEmpty = 'false';
      input.value = '';
      input.dispatchEvent(new Event('input'));
      expect(validator.errorMessage).toBe('Too short');
    });

    it('sets error message for empty input if allowEmpty is not defined', () => {
      input.value = '';
      input.dispatchEvent(new Event('input'));
      expect(validator.errorMessage).toBe('Too short');
    });
  });
});
