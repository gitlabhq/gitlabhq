import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import MockAxiosAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import SharedRunnersForm from '~/group_settings/components/shared_runners_form.vue';
import { ENABLED, DISABLED, ALLOW_OVERRIDE } from '~/group_settings/constants';
import axios from '~/lib/utils/axios_utils';

const TEST_UPDATE_PATH = '/test/update';
const DISABLED_PAYLOAD = { shared_runners_setting: DISABLED };
const ENABLED_PAYLOAD = { shared_runners_setting: ENABLED };
const OVERRIDE_PAYLOAD = { shared_runners_setting: ALLOW_OVERRIDE };

jest.mock('~/flash');

describe('group_settings/components/shared_runners_form', () => {
  let wrapper;
  let mock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SharedRunnersForm, {
      propsData: {
        updatePath: TEST_UPDATE_PATH,
        sharedRunnersAvailability: ENABLED,
        parentSharedRunnersAvailability: null,
        ...props,
      },
    });
  };

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findErrorAlert = () => wrapper.find(GlAlert);
  const findEnabledToggle = () => wrapper.find('[data-testid="enable-runners-toggle"]');
  const findOverrideToggle = () => wrapper.find('[data-testid="override-runners-toggle"]');
  const changeToggle = toggle => toggle.vm.$emit('change', !toggle.props('value'));
  const getRequestPayload = () => JSON.parse(mock.history.put[0].data);
  const isLoadingIconVisible = () => findLoadingIcon().exists();

  beforeEach(() => {
    mock = new MockAxiosAdapter(axios);

    mock.onPut(TEST_UPDATE_PATH).reply(200);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('with default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('loading icon does not exist', () => {
      expect(isLoadingIconVisible()).toBe(false);
    });

    it('enabled toggle exists', () => {
      expect(findEnabledToggle().exists()).toBe(true);
    });

    it('override toggle does not exist', () => {
      expect(findOverrideToggle().exists()).toBe(false);
    });
  });

  describe('loading icon', () => {
    it('shows and hides the loading icon on request', async () => {
      createComponent();

      expect(isLoadingIconVisible()).toBe(false);

      findEnabledToggle().vm.$emit('change', true);

      await wrapper.vm.$nextTick();

      expect(isLoadingIconVisible()).toBe(true);

      await waitForPromises();

      expect(isLoadingIconVisible()).toBe(false);
    });
  });

  describe('enable toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it('enabling the toggle sends correct payload', async () => {
      findEnabledToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(getRequestPayload()).toEqual(ENABLED_PAYLOAD);
      expect(findOverrideToggle().exists()).toBe(false);
    });

    it('disabling the toggle sends correct payload', async () => {
      findEnabledToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(getRequestPayload()).toEqual(DISABLED_PAYLOAD);
      expect(findOverrideToggle().exists()).toBe(true);
    });
  });

  describe('override toggle', () => {
    beforeEach(() => {
      createComponent({ sharedRunnersAvailability: ALLOW_OVERRIDE });
    });

    it('enabling the override toggle sends correct payload', async () => {
      findOverrideToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(getRequestPayload()).toEqual(OVERRIDE_PAYLOAD);
    });

    it('disabling the override toggle sends correct payload', async () => {
      findOverrideToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(getRequestPayload()).toEqual(DISABLED_PAYLOAD);
    });
  });

  describe('toggle disabled state', () => {
    it(`toggles are not disabled with setting ${DISABLED}`, () => {
      createComponent({ sharedRunnersAvailability: DISABLED });
      expect(findEnabledToggle().props('disabled')).toBe(false);
      expect(findOverrideToggle().props('disabled')).toBe(false);
    });

    it('toggles are disabled', () => {
      createComponent({
        sharedRunnersAvailability: DISABLED,
        parentSharedRunnersAvailability: DISABLED,
      });
      expect(findEnabledToggle().props('disabled')).toBe(true);
      expect(findOverrideToggle().props('disabled')).toBe(true);
    });
  });

  describe.each`
    errorObj                        | message
    ${{}}                           | ${'An error occurred while updating configuration. Refresh the page and try again.'}
    ${{ error: 'Undefined error' }} | ${'Undefined error Refresh the page and try again.'}
  `(`with error $errorObj`, ({ errorObj, message }) => {
    beforeEach(async () => {
      mock.onPut(TEST_UPDATE_PATH).reply(500, errorObj);

      createComponent();
      changeToggle(findEnabledToggle());

      await waitForPromises();
    });

    it('error should be shown', () => {
      expect(findErrorAlert().text()).toBe(message);
    });
  });
});
