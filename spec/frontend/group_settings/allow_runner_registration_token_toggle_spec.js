import { initAllowRunnerRegistrationTokenToggle } from '~/group_settings/allow_runner_registration_token_toggle';

import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('initAllowRunnerRegistrationTokenToggle', () => {
  let form;
  let requestSubmitMock;

  const setFormFixture = ({
    action = '/settings',
    hiddenInputValue = 'false',
    toggleDisabled = 'false',
    toggleIsChecked = 'false',
    toggleLabel = 'Toggle Label',
  } = {}) => {
    setHTMLFixture(`
      <form action="${action}">
        <input class="js-allow-runner-registration-token-input" value="${hiddenInputValue}" type="hidden" name="group[allow_runner_registration_token]"/>
        <span class="js-allow-runner-registration-token-toggle" data-disabled="${toggleDisabled}" data-is-checked="${toggleIsChecked}" data-is-loading="false" data-label="${toggleLabel}"></span>
      </form>
    `);

    initAllowRunnerRegistrationTokenToggle();

    form = document.querySelector('form');
    requestSubmitMock = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {});
  };

  const findInput = () => form.querySelector('[name="group[allow_runner_registration_token]"]');
  const findToggle = () => form.querySelector('[data-testid="toggle-wrapper"] button');

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders a toggle and hidden input', () => {
    setFormFixture();

    expect(form.textContent).toContain('Toggle Label');

    expect(findToggle()).toBeDefined();
    expect(findInput()).toBeDefined();
  });

  describe('when setting is enabled', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'true', toggleIsChecked: 'true' });
    });

    it('shows an "on" toggle', () => {
      expect(findInput().value).toBe('true');
      expect(findToggle().getAttribute('aria-checked')).toBe('true');
    });

    it('when clicked, toggles the setting', () => {
      findToggle().click();

      expect(findInput().value).toBe('false');
      expect(requestSubmitMock).toHaveBeenCalledTimes(1);
    });
  });
  describe('when setting is disabled', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'false', toggleIsChecked: 'false' });
    });

    it('shows an "off toggle"', () => {
      expect(findInput().value).toBe('false');
      expect(findToggle().getAttribute('aria-checked')).toBe('false');
    });

    it('when clicked, toggles the setting', () => {
      findToggle().click();

      expect(findInput().value).toBe('true');
      expect(requestSubmitMock).toHaveBeenCalledTimes(1);
    });
  });
});
