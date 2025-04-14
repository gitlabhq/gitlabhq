import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilepathFormMediator from '~/blob/filepath_form_mediator';

describe('Template Selector Mediator', () => {
  let input;
  let mediator;
  const editor = jest.fn().mockImplementationOnce(() => ({
    getValue: jest.fn().mockImplementation(() => {}),
  }))();

  beforeEach(() => {
    setHTMLFixture(`
      <div class="file-editor">
        <input class="js-file-path-name-input" />
        <div class="js-filepath-error gl-hidden"></div>
      </div>
    `);
    input = document.querySelector('.js-file-path-name-input');
    mediator = new FilepathFormMediator({
      editor,
      currentAction: jest.fn(),
      projectId: jest.fn(),
    });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('setFilename', () => {
    const newFileName = 'foo';

    it('fills out the input field', () => {
      expect(input.value).toBe('');
      mediator.setFilename(newFileName);
      expect(input.value).toBe(newFileName);
    });

    it.each`
      name           | newName        | shouldDispatch
      ${newFileName} | ${newFileName} | ${false}
      ${newFileName} | ${''}          | ${true}
      ${newFileName} | ${undefined}   | ${false}
      ${''}          | ${''}          | ${false}
      ${''}          | ${newFileName} | ${true}
      ${''}          | ${undefined}   | ${false}
    `(
      'correctly reacts to the name change when current name is $name and newName is $newName',
      ({ name, newName, shouldDispatch }) => {
        input.value = name;
        const eventHandler = jest.fn();
        input.addEventListener('input', eventHandler);

        mediator.setFilename(newName);
        if (shouldDispatch) {
          expect(eventHandler).toHaveBeenCalledTimes(1);
        } else {
          expect(eventHandler).not.toHaveBeenCalled();
        }
      },
    );
  });

  describe('toggleValidationError', () => {
    const getErrorElement = () => document.querySelector('.js-filepath-error');
    const inputErrorClasses = [
      'gl-border',
      '!gl-shadow-none',
      'gl-border-red-500',
      '!gl-shadow-none',
    ];

    it('shows error state when showError is true', () => {
      mediator.toggleValidationError(true);

      expect(getErrorElement().classList.contains('gl-hidden')).toBe(false);
      expect(input.classList).toContain(...inputErrorClasses);
    });

    it('hides error state when showError is false', () => {
      mediator.toggleValidationError(false);

      expect(getErrorElement().classList.contains('gl-hidden')).toBe(true);
      expect(input.classList).not.toContain(...inputErrorClasses);
    });
  });
});
