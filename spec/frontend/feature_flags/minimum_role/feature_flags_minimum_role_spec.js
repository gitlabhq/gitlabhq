import { GlAlert, GlButton, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { updateFeatureFlagsSettings } from '~/api/feature_flags_api';
import FeatureFlagsMinimumRole from '~/feature_flags/minimum_role/feature_flags_minimum_role.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

jest.mock('~/api/feature_flags_api');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('FeatureFlagsMinimumRole', () => {
  let wrapper;

  const projectFullPath = 'group/project';
  const showToast = jest.fn();

  const createComponent = ({ canUpdate = true, minimumRole = 'maintainer' } = {}) => {
    wrapper = shallowMount(FeatureFlagsMinimumRole, {
      provide: { projectFullPath, minimumRole, canUpdate },
      mocks: { $toast: { show: showToast } },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findSaveButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    updateFeatureFlagsSettings.mockResolvedValue({ data: { minimum_role: 'owner' } });
  });

  describe('on load', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders every role option', () => {
      expect(wrapper.findAllComponents(GlFormRadio).wrappers.map((w) => w.props('value'))).toEqual([
        'no_one_allowed',
        'owner',
        'maintainer',
        'developer',
      ]);
    });

    it('selects the role rendered by the server', () => {
      expect(findRadioGroup().props('checked')).toBe('maintainer');
    });
  });

  describe('saving', () => {
    beforeEach(() => {
      createComponent();
      findRadioGroup().vm.$emit('input', 'owner');
    });

    it('sends the selected role and shows a toast', async () => {
      findSaveButton().vm.$emit('click');
      await waitForPromises();

      expect(updateFeatureFlagsSettings).toHaveBeenCalledWith(projectFullPath, {
        minimumRole: 'owner',
      });
      expect(showToast).toHaveBeenCalledWith('Minimum role successfully updated.');
      expect(findAlert().exists()).toBe(false);
    });

    it('surfaces the API error message', async () => {
      updateFeatureFlagsSettings.mockRejectedValue({
        response: { data: { message: 'Changing the minimum role is not allowed' } },
      });

      findSaveButton().vm.$emit('click');
      await waitForPromises();

      expect(findAlert().text()).toBe('Changing the minimum role is not allowed');
    });

    it('explains the lock instead of showing a bare 403', async () => {
      updateFeatureFlagsSettings.mockRejectedValue({
        response: { status: 403, data: { message: '403 Forbidden' } },
      });

      findSaveButton().vm.$emit('click');
      await waitForPromises();

      expect(findAlert().text()).toBe(
        'Only project Owners can change this setting while it is set to Owner or No one.',
      );
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('falls back to a generic message when the API sends none', async () => {
      updateFeatureFlagsSettings.mockRejectedValue(new Error('boom'));

      findSaveButton().vm.$emit('click');
      await waitForPromises();

      expect(findAlert().text()).toBe('Could not update the minimum role setting.');
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('when the user cannot update the setting', () => {
    beforeEach(() => {
      createComponent({ canUpdate: false });
    });

    it('disables the radios and hides the save button', () => {
      expect(findRadioGroup().attributes('disabled')).toBeDefined();
      expect(findSaveButton().exists()).toBe(false);
    });

    it('explains why the setting is locked', () => {
      expect(wrapper.text()).toContain(
        'Only project Owners can change this setting while it is set to Owner or No one.',
      );
    });
  });
});
