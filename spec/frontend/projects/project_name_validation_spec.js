import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { validateProjectName, initProjectNameValidation } from '~/projects/project_name_validation';

describe('Project name validation', () => {
  describe('with DOM', () => {
    let input;
    let error;
    let description;

    beforeEach(() => {
      setHTMLFixture(`
        <form class="js-general-settings-form">
          <input id="project_name_edit" aria-invalid="false" aria-describedby="js-project-name-edit-description" />
          <small id="js-project-name-edit-description">Help text</small>
          <div class="gl-field-error gl-hidden" id="js-project-name-edit-error" role="alert"></div>
        </form>
      `);

      input = document.querySelector('#project_name_edit');
      error = document.querySelector('#js-project-name-edit-error');
      description = document.querySelector('#js-project-name-edit-description');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    describe('validateProjectName', () => {
      it('shows the error and sets ARIA attributes when the name is invalid', () => {
        input.value = '.invalid';

        const result = validateProjectName(input, error, description);

        expect(result).toBe(true);
        expect(error.innerText).toBe(
          'Project name must start with a letter, digit, basic emoji, or underscore.',
        );
        expect(error.classList.contains('gl-hidden')).toBe(false);
        expect(description.classList.contains('gl-hidden')).toBe(true);
        expect(input.getAttribute('aria-invalid')).toBe('true');
        expect(input.getAttribute('aria-describedby')).toBe('js-project-name-edit-error');
      });

      it('shows the required error when the name is empty', () => {
        input.value = '   ';

        const result = validateProjectName(input, error, description);

        expect(result).toBe(true);
        expect(error.innerText).toBe('Project name is required.');
      });

      it('hides the error and restores the description when the name is valid', () => {
        input.value = 'valid-name';

        const result = validateProjectName(input, error, description);

        expect(result).toBe(false);
        expect(error.classList.contains('gl-hidden')).toBe(true);
        expect(description.classList.contains('gl-hidden')).toBe(false);
        expect(input.getAttribute('aria-invalid')).toBe('false');
        expect(input.getAttribute('aria-describedby')).toBe('js-project-name-edit-description');
      });

      it('removes aria-describedby when no description is provided and the name is valid', () => {
        input.value = 'valid-name';

        validateProjectName(input, error, null);

        expect(input.getAttribute('aria-describedby')).toBe(null);
      });

      it('returns false when the error element is missing', () => {
        expect(validateProjectName(input, null, description)).toBe(false);
      });
    });

    describe('initProjectNameValidation', () => {
      let form;

      beforeEach(() => {
        form = document.querySelector('.js-general-settings-form');
        initProjectNameValidation();
      });

      it('validates on keyup', () => {
        input.value = '.invalid';

        input.dispatchEvent(new KeyboardEvent('keyup'));

        expect(error.classList.contains('gl-hidden')).toBe(false);
        expect(input.getAttribute('aria-invalid')).toBe('true');
      });

      it('validates on change', () => {
        input.value = '.invalid';

        input.dispatchEvent(new Event('change'));

        expect(error.classList.contains('gl-hidden')).toBe(false);
      });

      it('prevents form submission and stops propagation when the name is invalid', () => {
        input.value = '.invalid';

        const bubbleHandler = jest.fn();
        document.body.addEventListener('submit', bubbleHandler);

        const event = new Event('submit', { bubbles: true, cancelable: true });
        form.dispatchEvent(event);

        expect(event.defaultPrevented).toBe(true);
        expect(bubbleHandler).not.toHaveBeenCalled();

        document.body.removeEventListener('submit', bubbleHandler);
      });

      it('does not prevent form submission when the name is valid', () => {
        input.value = 'valid-name';

        const event = new Event('submit', { bubbles: true, cancelable: true });
        form.dispatchEvent(event);

        expect(event.defaultPrevented).toBe(false);
      });
    });
  });
});
