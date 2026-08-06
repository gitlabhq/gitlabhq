import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initGroupNameValidation } from '~/groups/group_name_validation';

describe('initGroupNameValidation', () => {
  const findInput = () => document.querySelector('#group_name_edit');
  const findError = () => document.querySelector('#js-group-name-edit-error');
  const findDescription = () => document.querySelector('#js-group-name-edit-description');

  const setInputValue = (value) => {
    findInput().value = value;
    findInput().dispatchEvent(new Event('input'));
  };

  const dispatchInvalid = () => {
    const event = new Event('invalid', { cancelable: true });
    findInput().dispatchEvent(event);

    return event;
  };

  beforeEach(() => {
    setHTMLFixture(`
      <form class="js-general-settings-form">
        <input id="group_name_edit" aria-invalid="false" required />
        <span id="js-group-name-edit-description">Start with a letter, digit, basic emoji, or underscore.</span>
        <div class="gl-field-error gl-hidden" id="js-group-name-edit-error" role="alert"></div>
      </form>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when the name is invalid', () => {
    beforeEach(() => {
      initGroupNameValidation();
      setInputValue('.invalid');
    });

    it('sets a custom HTML5 validity message so the form cannot be submitted', () => {
      expect(findInput().validity.valid).toBe(false);
      expect(findInput().validationMessage).toBe(
        'Group name must start with a letter, digit, emoji, or underscore.',
      );
    });

    it('renders the inline error with matching ARIA attributes', () => {
      expect(findError().classList.contains('gl-hidden')).toBe(false);
      expect(findError().textContent).toBe(
        'Group name must start with a letter, digit, emoji, or underscore.',
      );
      expect(findInput().getAttribute('aria-invalid')).toBe('true');
      expect(findInput().getAttribute('aria-describedby')).toBe('js-group-name-edit-error');
    });

    it('hides the field description so it does not compete with the error', () => {
      expect(findDescription().classList.contains('gl-hidden')).toBe(true);
    });

    it("suppresses the browser's native validation tooltip", () => {
      expect(dispatchInvalid().defaultPrevented).toBe(true);
    });
  });

  describe('when the name is empty', () => {
    beforeEach(() => {
      initGroupNameValidation();
      setInputValue('');
    });

    it('renders the required-field message', () => {
      expect(findInput().validity.valid).toBe(false);
      expect(findInput().validationMessage).toBe('Group name is required.');
      expect(findError().textContent).toBe('Group name is required.');
    });
  });

  describe('when the name becomes valid', () => {
    beforeEach(() => {
      initGroupNameValidation();
      // Start from an invalid state to prove clearing works
      setInputValue('.invalid');
      setInputValue('valid name');
    });

    it('clears the HTML5 custom validity', () => {
      expect(findInput().validity.valid).toBe(true);
      expect(findInput().validationMessage).toBe('');
    });

    it('hides the inline error and resets ARIA attributes', () => {
      expect(findError().classList.contains('gl-hidden')).toBe(true);
      expect(findInput().getAttribute('aria-invalid')).toBe('false');
      expect(findInput().getAttribute('aria-describedby')).toBe(null);
    });

    it('restores the field description', () => {
      expect(findDescription().classList.contains('gl-hidden')).toBe(false);
    });
  });

  describe('when the field becomes invalid without a prior input event', () => {
    beforeEach(() => {
      initGroupNameValidation();
      // For example, a submit against a programmatically-cleared field
      findInput().value = '';
      dispatchInvalid();
    });

    it('renders the inline error', () => {
      expect(findError().classList.contains('gl-hidden')).toBe(false);
      expect(findError().textContent).toBe('Group name is required.');
      expect(findInput().getAttribute('aria-invalid')).toBe('true');
      expect(findDescription().classList.contains('gl-hidden')).toBe(true);
    });
  });

  describe('when the field description is missing', () => {
    beforeEach(() => {
      findDescription().remove();
      initGroupNameValidation();
    });

    it('still renders the inline error', () => {
      setInputValue('.invalid');

      expect(findError().classList.contains('gl-hidden')).toBe(false);
    });
  });

  describe('when the name field is missing', () => {
    it('does nothing', () => {
      findInput().remove();

      expect(() => initGroupNameValidation()).not.toThrow();
    });
  });

  describe('when the error element is missing', () => {
    it('does nothing', () => {
      findError().remove();

      expect(() => initGroupNameValidation()).not.toThrow();
    });
  });
});
