import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import { updateApplicationSettings } from '~/rest_api';
import SilentModeSettingsApp from '~/silent_mode_settings/components/app.vue';

jest.mock('~/rest_api.js');
jest.mock('~/alert');
jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_DEFAULT_SILENT_MODE_ENABLED = false;

describe('SilentModeSettingsApp', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    const defaultProps = {
      isSilentModeEnabled: MOCK_DEFAULT_SILENT_MODE_ENABLED,
    };

    wrapper = shallowMount(SilentModeSettingsApp, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlToggle = () => wrapper.findComponent(GlToggle);

  describe('template', () => {
    describe('when silent mode is already enabled', () => {
      beforeEach(() => {
        createComponent({ isSilentModeEnabled: true });
      });

      it('renders the component with the GlToggle set to true', () => {
        expect(findGlToggle().attributes('value')).toBe('true');
      });
    });

    describe('when silent mode is no already enabled', () => {
      beforeEach(() => {
        createComponent({ isSilentModeEnabled: false });
      });

      it('renders the component with the GlToggle set to undefined', () => {
        expect(findGlToggle().attributes('value')).toBeUndefined();
      });
    });
  });

  describe.each`
    enabled  | message
    ${false} | ${'Silent mode disabled'}
    ${true}  | ${'Silent mode enabled'}
  `(`toast message`, ({ enabled, message }) => {
    beforeEach(() => {
      updateApplicationSettings.mockImplementation(() => Promise.resolve());
      createComponent();
    });

    it(`when successfully toggled to ${enabled}, toast message is ${message}`, async () => {
      await findGlToggle().vm.$emit('change', enabled);
      await waitForPromises();

      expect(toast).toHaveBeenCalledWith(message);
    });
  });

  describe.each`
    description    | mockApi                    | toastMsg                 | error
    ${'onSuccess'} | ${() => Promise.resolve()} | ${'Silent mode enabled'} | ${false}
    ${'onError'}   | ${() => Promise.reject()}  | ${false}                 | ${'There was an error updating the Silent Mode Settings.'}
  `(`when submitting the form $description`, ({ mockApi, toastMsg, error }) => {
    beforeEach(() => {
      updateApplicationSettings.mockImplementation(mockApi);

      createComponent();
    });

    it('calls updateApplicationSettings correctly', () => {
      findGlToggle().vm.$emit('change', !MOCK_DEFAULT_SILENT_MODE_ENABLED);

      expect(updateApplicationSettings).toHaveBeenCalledWith({
        silent_mode_enabled: !MOCK_DEFAULT_SILENT_MODE_ENABLED,
      });
    });

    it('handles the loading icon correctly', async () => {
      expect(findGlToggle().props('isLoading')).toBe(false);

      await findGlToggle().vm.$emit('change', !MOCK_DEFAULT_SILENT_MODE_ENABLED);

      expect(findGlToggle().props('isLoading')).toBe(true);

      await waitForPromises();

      expect(findGlToggle().props('isLoading')).toBe(false);
    });

    it(`does ${toastMsg ? '' : 'not '}render an success toast message`, async () => {
      await findGlToggle().vm.$emit('change', !MOCK_DEFAULT_SILENT_MODE_ENABLED);
      await waitForPromises();

      return toastMsg
        ? expect(toast).toHaveBeenCalledWith(toastMsg)
        : expect(toast).not.toHaveBeenCalled();
    });

    it(`does ${error ? '' : 'not '}render an error message`, async () => {
      await findGlToggle().vm.$emit('change', !MOCK_DEFAULT_SILENT_MODE_ENABLED);
      await waitForPromises();

      return error
        ? expect(createAlert).toHaveBeenCalledWith({ message: error })
        : expect(createAlert).not.toHaveBeenCalled();
    });
  });
});
