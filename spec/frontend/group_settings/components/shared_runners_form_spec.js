import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SharedRunnersForm from '~/group_settings/components/shared_runners_form.vue';
import { updateGroup } from '~/api/groups_api';

jest.mock('~/api/groups_api');

const GROUP_ID = '99';
const RUNNER_ENABLED_VALUE = 'enabled';
const RUNNER_DISABLED_VALUE = 'disabled_and_unoverridable';
const RUNNER_ALLOW_OVERRIDE_VALUE = 'disabled_and_overridable';

describe('group_settings/components/shared_runners_form', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(SharedRunnersForm, {
      provide: {
        groupId: GROUP_ID,
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
  const getSharedRunnersSetting = () => {
    return updateGroup.mock.calls[0][1].shared_runners_setting;
  };

  beforeEach(() => {
    updateGroup.mockResolvedValue({});
  });

  afterEach(() => {
    updateGroup.mockReset();
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

      expect(updateGroup).toHaveBeenCalledTimes(1);
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
    errorData                       | message
    ${{}}                           | ${'An error occurred while updating configuration. Refresh the page and try again.'}
    ${{ error: 'Undefined error' }} | ${'Undefined error Refresh the page and try again.'}
  `(`with error $errorObj`, ({ errorData, message }) => {
    beforeEach(async () => {
      updateGroup.mockRejectedValue({
        response: { data: errorData },
      });

      createComponent();
      findSharedRunnersToggle().vm.$emit('change', false);

      await waitForPromises();
    });

    it('error should be shown', () => {
      expect(findAlert('danger').text()).toBe(message);
    });
  });
});
