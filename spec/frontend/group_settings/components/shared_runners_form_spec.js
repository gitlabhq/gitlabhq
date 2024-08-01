import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { updateGroup } from '~/api/groups_api';

import SharedRunnersForm from '~/group_settings/components/shared_runners_form.vue';
import { I18N_CONFIRM_MESSAGE } from '~/group_settings/constants';

jest.mock('~/api/groups_api');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const GROUP_ID = '99';
const GROUP_NAME = 'My group';
const RUNNER_ENABLED_VALUE = 'enabled';
const RUNNER_DISABLED_VALUE = 'disabled_and_unoverridable';
const RUNNER_ALLOW_OVERRIDE_VALUE = 'disabled_and_overridable';

const mockParentName = 'My group';
const mockParentSettingsPath = '/groups/my-group/-/settings/ci_cd';

describe('group_settings/components/shared_runners_form', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(SharedRunnersForm, {
      provide: {
        groupId: GROUP_ID,
        groupName: GROUP_NAME,
        groupIsEmpty: false,
        sharedRunnersSetting: RUNNER_ENABLED_VALUE,

        runnerEnabledValue: RUNNER_ENABLED_VALUE,
        runnerDisabledValue: RUNNER_DISABLED_VALUE,
        runnerAllowOverrideValue: RUNNER_ALLOW_OVERRIDE_VALUE,
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSharedRunnersToggle = () => wrapper.findByTestId('shared-runners-toggle');
  const findOverrideToggle = () => wrapper.findByTestId('override-runners-toggle');
  const getSharedRunnersSetting = () => {
    return updateGroup.mock.calls[0][1].shared_runners_setting;
  };

  beforeEach(() => {
    confirmAction.mockResolvedValue(true);
    updateGroup.mockResolvedValue({});
  });

  afterEach(() => {
    confirmAction.mockReset();
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

  describe.each`
    provide                                                                       | case                         | isParentLinkExpected
    ${{ parentName: mockParentName, parentSettingsPath: mockParentSettingsPath }} | ${'can configure parent'}    | ${true}
    ${{}}                                                                         | ${'cannot configure parent'} | ${false}
  `('When parent group disabled shared runners and $case', ({ provide, isParentLinkExpected }) => {
    beforeEach(() => {
      createComponent({
        sharedRunnersSetting: RUNNER_DISABLED_VALUE,
        parentSharedRunnersSetting: RUNNER_DISABLED_VALUE,
        ...provide,
      });
    });

    it.each([findSharedRunnersToggle, findOverrideToggle])(
      'toggle %# is disabled',
      (findToggle) => {
        expect(findToggle().props('disabled')).toBe(true);
        expect(findToggle().text()).toContain('Instance runners are disabled.');

        if (isParentLinkExpected) {
          expect(findToggle().text()).toContain(
            sprintf('Go to %{groupLink} to enable them.', {
              groupLink: mockParentName,
            }),
          );
          const link = findToggle().findComponent(GlLink);
          expect(link.text()).toBe(mockParentName);
          expect(link.attributes('href')).toBe(mockParentSettingsPath);
        }
      },
    );
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
      await nextTick();
      findSharedRunnersToggle().vm.$emit('change', false);
      await nextTick();

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

      expect(confirmAction).not.toHaveBeenCalled();

      expect(getSharedRunnersSetting()).toEqual(RUNNER_ENABLED_VALUE);
      expect(findOverrideToggle().props('disabled')).toBe(true);
    });

    it('sends correct payload when turned off', async () => {
      findSharedRunnersToggle().vm.$emit('change', false);
      await waitForPromises();

      expect(confirmAction).toHaveBeenCalledTimes(1);
      expect(confirmAction).toHaveBeenCalledWith(
        I18N_CONFIRM_MESSAGE,
        expect.objectContaining({
          title: expect.stringContaining(GROUP_NAME),
        }),
      );

      expect(getSharedRunnersSetting()).toEqual(RUNNER_DISABLED_VALUE);
      expect(findOverrideToggle().props('disabled')).toBe(false);
    });

    describe('when user cancels operation', () => {
      beforeEach(() => {
        confirmAction.mockResolvedValue(false);
      });

      it('sends no payload when turned off', async () => {
        findSharedRunnersToggle().vm.$emit('change', false);
        await waitForPromises();

        expect(confirmAction).toHaveBeenCalledTimes(1);
        expect(confirmAction).toHaveBeenCalledWith(
          I18N_CONFIRM_MESSAGE,
          expect.objectContaining({
            title: expect.stringContaining(GROUP_NAME),
          }),
        );

        expect(updateGroup).not.toHaveBeenCalled();
        expect(findOverrideToggle().props('disabled')).toBe(true);
      });
    });

    describe('when group is empty', () => {
      beforeEach(() => {
        createComponent({ groupIsEmpty: true });
      });

      it('confirmation is not shown when turned off', async () => {
        findSharedRunnersToggle().vm.$emit('change', false);
        await waitForPromises();

        expect(confirmAction).not.toHaveBeenCalled();
        expect(getSharedRunnersSetting()).toEqual(RUNNER_DISABLED_VALUE);
      });
    });
  });

  describe('"Override the group setting" toggle', () => {
    it('enabling the override toggle sends correct payload', async () => {
      createComponent({ sharedRunnersSetting: RUNNER_ALLOW_OVERRIDE_VALUE });

      findOverrideToggle().vm.$emit('change', true);
      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(RUNNER_ALLOW_OVERRIDE_VALUE);
    });

    it('disabling the override toggle sends correct payload', async () => {
      createComponent({ sharedRunnersSetting: RUNNER_ALLOW_OVERRIDE_VALUE });

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
      expect(findAlert().text()).toBe(message);
    });
  });
});
