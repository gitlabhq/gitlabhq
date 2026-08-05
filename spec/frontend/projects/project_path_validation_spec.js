import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { validateProjectPath } from '~/projects/project_path_validation';

describe('Project path validation', () => {
  let input;
  let error;

  beforeEach(() => {
    setHTMLFixture(`
      <input id="project_path" aria-invalid="false" />
      <div class="gl-field-error gl-hidden" id="js-project-path-error" role="alert"></div>
    `);

    input = document.querySelector('#project_path');
    error = document.querySelector('#js-project-path-error');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('validateProjectPath', () => {
    it('shows the error and sets ARIA attributes when the path is invalid', () => {
      input.value = '-bad';

      const result = validateProjectPath(input, error);

      expect(result).toBe(true);
      expect(error.innerText).toBe('Project slug must start with a letter or digit.');
      expect(error.classList.contains('gl-hidden')).toBe(false);
      expect(input.getAttribute('aria-invalid')).toBe('true');
      expect(input.getAttribute('aria-describedby')).toBe('js-project-path-error');
    });

    it('hides the error and removes ARIA attributes when the path is valid', () => {
      input.value = 'my-awesome-project';

      const result = validateProjectPath(input, error);

      expect(result).toBe(false);
      expect(error.classList.contains('gl-hidden')).toBe(true);
      expect(input.getAttribute('aria-invalid')).toBe('false');
      expect(input.getAttribute('aria-describedby')).toBe(null);
    });

    it('returns false when the error element is missing', () => {
      expect(validateProjectPath(input, null)).toBe(false);
    });

    it('returns false for an empty path', () => {
      input.value = '';

      expect(validateProjectPath(input, error)).toBe(false);
    });
  });
});
