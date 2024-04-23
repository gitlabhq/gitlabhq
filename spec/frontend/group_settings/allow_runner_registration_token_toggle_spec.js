import { GlToggle } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import { initAllowRunnerRegistrationTokenToggle } from '~/group_settings/allow_runner_registration_token_toggle';

describe('initAllowRunnerRegistrationTokenToggle', () => {
  let form;
  let wrapper;
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

    const toggle = initAllowRunnerRegistrationTokenToggle();

    form = document.querySelector('form');
    wrapper = createWrapper(toggle);

    requestSubmitMock = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {});
  };

  const findInput = () => form.querySelector('[name="group[allow_runner_registration_token]"]');
  const findToggle = () => wrapper.findComponent(GlToggle);

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders a toggle and hidden input', () => {
    setFormFixture();

    expect(form.textContent).toContain('Toggle Label');

    expect(findToggle().exists()).toBeDefined();
    expect(findInput()).toBeDefined();
  });

  describe('when setting is enabled', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'true', toggleIsChecked: 'true' });
    });

    it('shows an "on" toggle', () => {
      expect(findToggle().props('value')).toBe(true);
      expect(findInput().value).toBe('true');
    });

    it('when clicked, toggles the setting', async () => {
      findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(findToggle().props('isLoading')).toBe(true);
      expect(findInput().value).toBe('false');

      expect(requestSubmitMock).toHaveBeenCalledTimes(1);
    });
  });

  describe('when setting is disabled', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'false', toggleIsChecked: 'false' });
    });

    it('shows an "off toggle"', () => {
      expect(findToggle().props('value')).toBe(false);
      expect(findInput().value).toBe('false');
    });

    it('when clicked, toggles the setting', async () => {
      findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(findToggle().props('isLoading')).toBe(true);
      expect(findInput().value).toBe('true');
      expect(requestSubmitMock).toHaveBeenCalledTimes(1);
    });
  });
});
