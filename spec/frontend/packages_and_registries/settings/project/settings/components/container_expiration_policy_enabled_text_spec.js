import { GlIcon, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContainerExpirationPolicyEnabledText from '~/packages_and_registries/settings/project/components/container_expiration_policy_enabled_text.vue';

describe('ContainerExpirationPolicyEnabledText', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findEnabledText = () => wrapper.findByTestId('enabled');
  const findNextCleanupAt = () => wrapper.findByTestId('next-cleanup-at');

  const createComponent = (nextRunAt = '2020-11-19T07:37:03.941Z') => {
    wrapper = shallowMountExtended(ContainerExpirationPolicyEnabledText, {
      propsData: {
        nextRunAt,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  describe('layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders enabled icon & text', () => {
      expect(findIcon().props()).toMatchObject({
        name: 'check-circle-filled',
        variant: 'success',
      });
      expect(findEnabledText().text()).toBe('Enabled');
    });

    it('renders next cleanup schedule', () => {
      expect(findNextCleanupAt().text()).toBe(
        'Next cleanup on November 19, 2020 at 7:37:03 AM GMT',
      );
    });
  });

  describe('with invalid date', () => {
    beforeEach(() => {
      createComponent('invalid date');
    });

    it('does not render next cleanup schedule', () => {
      expect(findNextCleanupAt().exists()).toBe(false);
    });
  });
});
