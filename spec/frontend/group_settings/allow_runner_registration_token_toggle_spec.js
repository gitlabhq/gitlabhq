import { GlToggle } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import toast from '~/vue_shared/plugins/global_toast';

import { initAllowRunnerRegistrationTokenToggle } from '~/group_settings/allow_runner_registration_token_toggle';

jest.mock('~/vue_shared/plugins/global_toast');

describe('initAllowRunnerRegistrationTokenToggle', () => {
  let form;
  let wrapper;
  let requestSubmitMock;

  const toastMessage = { hide: jest.fn() };
  toast.mockImplementation(() => toastMessage);

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

    requestSubmitMock = jest.spyOn(axios, 'post').mockImplementation(
      () =>
        new Promise((resolve) => {
          resolve({});
        }),
    );
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
      await findToggle().vm.$emit('change', false);

      expect(findToggle().props('isLoading')).toBe(true);

      await waitForPromises();

      expect(findToggle().props('isLoading')).toBe(false);
      expect(findInput().value).toBe('false');
      expect(requestSubmitMock).toHaveBeenCalledWith(form.action, new FormData(form));
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
      await findToggle().vm.$emit('change', true);

      expect(findToggle().props('isLoading')).toBe(true);

      await waitForPromises();

      expect(findToggle().props('isLoading')).toBe(false);
      expect(findInput().value).toBe('true');
      expect(requestSubmitMock).toHaveBeenCalledWith(form.action, new FormData(form));
    });
  });

  describe('when update request is pending', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'true', toggleIsChecked: 'true' });
    });

    it('shows a pending message', () => {
      findToggle().vm.$emit('change', false);

      expect(toast).toHaveBeenCalledWith('Saving...', {});
    });
  });

  describe('when update request is successful', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'true', toggleIsChecked: 'true' });
    });

    it('shows a success message', async () => {
      findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(toastMessage.hide).toHaveBeenCalled();
      expect(toast).toHaveBeenCalledWith('Change saved.', {
        action: {
          onClick: expect.any(Function),
          text: 'Undo',
        },
      });
    });
  });

  describe('when update request fails', () => {
    beforeEach(() => {
      setFormFixture({ hiddenInputValue: 'true', toggleIsChecked: 'true' });

      requestSubmitMock = jest.spyOn(axios, 'post').mockImplementation(
        () =>
          new Promise((resolve, reject) => {
            reject(new Error('Some error'));
          }),
      );
    });

    it('shows an error message and restores the inputs to the previous values', async () => {
      findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(findInput().value).toBe('true');
      expect(toastMessage.hide).toHaveBeenCalled();
      expect(toast).toHaveBeenCalledWith('Failed to save changes.', {
        action: {
          onClick: expect.any(Function),
          text: 'Retry',
        },
      });
    });
  });
});
