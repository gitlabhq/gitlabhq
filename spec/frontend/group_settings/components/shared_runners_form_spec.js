import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAxiosAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import SharedRunnersForm from '~/group_settings/components/shared_runners_form.vue';
import axios from '~/lib/utils/axios_utils';

const provide = {
  updatePath: '/test/update',
  sharedRunnersAvailability: 'enabled',
  parentSharedRunnersAvailability: null,
  runnerDisabled: 'disabled',
  runnerEnabled: 'enabled',
  runnerAllowOverride: 'allow_override',
};

jest.mock('~/flash');

describe('group_settings/components/shared_runners_form', () => {
  let wrapper;
  let mock;

  const createComponent = (provides = {}) => {
    wrapper = shallowMount(SharedRunnersForm, {
      provide: {
        ...provide,
        ...provides,
      },
    });
  };

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findErrorAlert = () => wrapper.find(GlAlert);
  const findEnabledToggle = () => wrapper.find('[data-testid="enable-runners-toggle"]');
  const findOverrideToggle = () => wrapper.find('[data-testid="override-runners-toggle"]');
  const changeToggle = (toggle) => toggle.vm.$emit('change', !toggle.props('value'));
  const getSharedRunnersSetting = () => JSON.parse(mock.history.put[0].data).shared_runners_setting;
  const isLoadingIconVisible = () => findLoadingIcon().exists();

  beforeEach(() => {
    mock = new MockAxiosAdapter(axios);

    mock.onPut(provide.updatePath).reply(200);
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

      await nextTick();

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

      expect(getSharedRunnersSetting()).toEqual(provide.runnerEnabled);
      expect(findOverrideToggle().exists()).toBe(false);
    });

    it('disabling the toggle sends correct payload', async () => {
      findEnabledToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(provide.runnerDisabled);
      expect(findOverrideToggle().exists()).toBe(true);
    });
  });

  describe('override toggle', () => {
    beforeEach(() => {
      createComponent({ sharedRunnersAvailability: provide.runnerAllowOverride });
    });

    it('enabling the override toggle sends correct payload', async () => {
      findOverrideToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(provide.runnerAllowOverride);
    });

    it('disabling the override toggle sends correct payload', async () => {
      findOverrideToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(getSharedRunnersSetting()).toEqual(provide.runnerDisabled);
    });
  });

  describe('toggle disabled state', () => {
    it(`toggles are not disabled with setting ${provide.runnerDisabled}`, () => {
      createComponent({ sharedRunnersAvailability: provide.runnerDisabled });
      expect(findEnabledToggle().props('disabled')).toBe(false);
      expect(findOverrideToggle().props('disabled')).toBe(false);
    });

    it('toggles are disabled', () => {
      createComponent({
        sharedRunnersAvailability: provide.runnerDisabled,
        parentSharedRunnersAvailability: provide.runnerDisabled,
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
      mock.onPut(provide.updatePath).reply(500, errorObj);

      createComponent();
      changeToggle(findEnabledToggle());

      await waitForPromises();
    });

    it('error should be shown', () => {
      expect(findErrorAlert().text()).toBe(message);
    });
  });
});
