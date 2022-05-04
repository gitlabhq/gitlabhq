import { GlAlert } from '@gitlab/ui';
import MockAxiosAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SharedRunnersForm from '~/group_settings/components/shared_runners_form.vue';
import axios from '~/lib/utils/axios_utils';

const UPDATE_PATH = '/test/update';
const RUNNER_ENABLED_VALUE = 'enabled';
const RUNNER_DISABLED_VALUE = 'disabled_and_unoverridable';
const RUNNER_ALLOW_OVERRIDE_VALUE = 'disabled_with_override';

describe('group_settings/components/shared_runners_form', () => {
  let wrapper;
  let mock;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(SharedRunnersForm, {
      provide: {
        updatePath: UPDATE_PATH,
        sharedRunnersSetting: RUNNER_ENABLED_VALUE,
        parentSharedRunnersSetting: null,
        runnerEnabledValue: RUNNER_ENABLED_VALUE,
        runnerDisabledValue: RUNNER_DISABLED_VALUE,
        runnerAllowOverrideValue: RUNNER_ALLOW_OVERRIDE_VALUE,
        ...provide,
      },
    });
  };

  const findAlert = (variant) =>
    wrapper
      .findAllComponents(GlAlert)
      .filter((w) => w.props('variant') === variant)
      .at(0);
  const findSharedRunnersToggle = () => wrapper.findByTestId('shared-runners-toggle');
  const findOverrideToggle = () => wrapper.findByTestId('override-runners-toggle');
  const getSharedRunnersSetting = () => JSON.parse(mock.history.put[0].data).shared_runners_setting;

  beforeEach(() => {
    mock = new MockAxiosAdapter(axios);
    mock.onPut(UPDATE_PATH).reply(200);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('"Enable shared runners" toggle is enabled', () => {
      expect(findSharedRunnersToggle().props()).toMatchObject({
        isLoading: false,
        disabled: false,
      });
    });

    it('"Override the group setting" is disabled', () => {
      expect(findOverrideToggle().props()).toMatchObject({
        isLoading: false,
        disabled: true,
      });
    });
  });

  describe('When group disabled shared runners', () => {
    it(`toggles are not disabled with setting ${RUNNER_DISABLED_VALUE}`, () => {
      createComponent({ sharedRunnersSetting: RUNNER_DISABLED_VALUE });

      expect(findSharedRunnersToggle().props('disabled')).toBe(false);
      expect(findOverrideToggle().props('disabled')).toBe(false);
    });
  });

  describe('When parent group disabled shared runners', () => {
    it('toggles are disabled', () => {
      createComponent({
        sharedRunnersSetting: RUNNER_DISABLED_VALUE,
        parentSharedRunnersSetting: RUNNER_DISABLED_VALUE,
      });

      expect(findSharedRunnersToggle().props('disabled')).toBe(true);
      expect(findOverrideToggle().props('disabled')).toBe(true);
      expect(findAlert('warning').exists()).toBe(true);
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is not loading by default', () => {
      expect(findSharedRunnersToggle().props('isLoading')).toBe(false);
      expect(findOverrideToggle().props('isLoading')).toBe(false);
    });

    it('is loading immediately after request', async () => {
      findSharedRunnersToggle().vm.$emit('change', true);
      await nextTick();

      expect(findSharedRunnersToggle().props('isLoading')).toBe(true);
      expect(findOverrideToggle().props('isLoading')).toBe(true);
    });

    it('does not update settings while loading', async () => {
      findSharedRunnersToggle().vm.$emit('change', true);
      findSharedRunnersToggle().vm.$emit('change', false);
      await waitForPromises();

      expect(mock.history.put.length).toBe(1);
    });

    it('is not loading state after completed request', async () => {
      findSharedRunnersToggle().vm.$emit('change', true);
      await waitForPromises();

      expect(findSharedRunnersToggle().props('isLoading')).toBe(false);
      expect(findOverrideToggle().props('isLoading')).toBe(false);
    });
  });

  describe('"Enable shared runners" toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sends correct payload when turned on', async () => {
      findSharedRunnersToggle().vm.$emit('change', true);
      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(RUNNER_ENABLED_VALUE);
      expect(findOverrideToggle().props('disabled')).toBe(true);
    });

    it('sends correct payload when turned off', async () => {
      findSharedRunnersToggle().vm.$emit('change', false);
      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(RUNNER_DISABLED_VALUE);
      expect(findOverrideToggle().props('disabled')).toBe(false);
    });
  });

  describe('"Override the group setting" toggle', () => {
    beforeEach(() => {
      createComponent({ sharedRunnersSetting: RUNNER_ALLOW_OVERRIDE_VALUE });
    });

    it('enabling the override toggle sends correct payload', async () => {
      findOverrideToggle().vm.$emit('change', true);
      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(RUNNER_ALLOW_OVERRIDE_VALUE);
    });

    it('disabling the override toggle sends correct payload', async () => {
      findOverrideToggle().vm.$emit('change', false);
      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(RUNNER_DISABLED_VALUE);
    });
  });

  describe.each`
    errorObj                        | message
    ${{}}                           | ${'An error occurred while updating configuration. Refresh the page and try again.'}
    ${{ error: 'Undefined error' }} | ${'Undefined error Refresh the page and try again.'}
  `(`with error $errorObj`, ({ errorObj, message }) => {
    beforeEach(async () => {
      mock.onPut(UPDATE_PATH).reply(500, errorObj);

      createComponent();
      findSharedRunnersToggle().vm.$emit('change', false);

      await waitForPromises();
    });

    it('error should be shown', () => {
      expect(findAlert('danger').text()).toBe(message);
    });
  });
});
