import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import eventHub from '~/projects/new/event_hub';
import initReadmeCheckboxToggle, {
  DISABLED_MESSAGE,
  DEFAULT_HELP_TEXT,
} from '~/projects/project_readme_checkbox';

describe('initReadmeCheckboxToggle', () => {
  const CHECKBOX_SELECTOR = '[data-testid="initialize-with-readme-checkbox"]';
  const HELP_TEXT_SELECTOR = '[data-testid="pajamas-component-help-text"]';

  const createCheckboxFixture = ({ disabled = false, checked = true } = {}) => {
    setHTMLFixture(`
      <div class="custom-control custom-checkbox">
        <input
          type="checkbox"
          data-testid="initialize-with-readme-checkbox"
          ${disabled ? 'disabled' : ''}
          ${checked ? 'checked' : ''}
        />
        <label class="custom-control-label">
          <span>Initialize repository with a README</span>
          <p class="help-text" data-testid="pajamas-component-help-text">
            ${disabled ? DISABLED_MESSAGE : DEFAULT_HELP_TEXT}
          </p>
        </label>
      </div>
    `);
  };

  const findCheckbox = () => document.querySelector(CHECKBOX_SELECTOR);
  const findHelpText = () => document.querySelector(HELP_TEXT_SELECTOR);

  afterEach(() => {
    resetHTMLFixture();
    eventHub.$off('update-readme-checkbox');
  });

  describe('when canPushInitialCommit is false', () => {
    beforeEach(() => {
      createCheckboxFixture();
      initReadmeCheckboxToggle();
      eventHub.$emit('update-readme-checkbox', { canPushInitialCommit: false });
    });

    it('disables the checkbox, unchecks it, and shows the disabled message', () => {
      expect(findCheckbox().disabled).toBe(true);
      expect(findCheckbox().checked).toBe(false);
      expect(findHelpText().textContent).toBe(DISABLED_MESSAGE);
    });
  });

  describe('when canPushInitialCommit is true', () => {
    beforeEach(() => {
      createCheckboxFixture({ disabled: true, checked: false });
      initReadmeCheckboxToggle();
      eventHub.$emit('update-readme-checkbox', { canPushInitialCommit: true });
    });

    it('enables the checkbox and shows the default help text', () => {
      expect(findCheckbox().disabled).toBe(false);
      expect(findCheckbox().checked).toBe(true);
      expect(findHelpText().textContent).toBe(DEFAULT_HELP_TEXT);
    });
  });

  describe('when canPushInitialCommit is undefined (user namespace)', () => {
    beforeEach(() => {
      createCheckboxFixture({ disabled: true, checked: false });
      initReadmeCheckboxToggle();
      eventHub.$emit('update-readme-checkbox', { canPushInitialCommit: undefined });
    });

    it('enables the checkbox and shows the default help text', () => {
      expect(findCheckbox().disabled).toBe(false);
      expect(findCheckbox().checked).toBe(true);
      expect(findHelpText().textContent).toBe(DEFAULT_HELP_TEXT);
    });
  });

  describe('when checkbox element does not exist in DOM', () => {
    it('does not throw an error', () => {
      setHTMLFixture('<div></div>');
      initReadmeCheckboxToggle();

      expect(() => {
        eventHub.$emit('update-readme-checkbox', { canPushInitialCommit: false });
      }).not.toThrow();
    });
  });

  describe('when switching from disabled to enabled namespace', () => {
    beforeEach(() => {
      createCheckboxFixture();
      initReadmeCheckboxToggle();
    });

    it('correctly toggles the checkbox state', () => {
      eventHub.$emit('update-readme-checkbox', { canPushInitialCommit: false });

      expect(findCheckbox().disabled).toBe(true);
      expect(findCheckbox().checked).toBe(false);
      expect(findHelpText().textContent).toBe(DISABLED_MESSAGE);

      eventHub.$emit('update-readme-checkbox', { canPushInitialCommit: true });

      expect(findCheckbox().disabled).toBe(false);
      expect(findCheckbox().checked).toBe(true);
      expect(findHelpText().textContent).toBe(DEFAULT_HELP_TEXT);
    });
  });
});
