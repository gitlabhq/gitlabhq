import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserLimitNotification from '~/invite_members/components/user_limit_notification.vue';
import { REACHED_LIMIT_VARIANT, CLOSE_TO_LIMIT_VARIANT } from '~/invite_members/constants';
import { freeUsersLimit, remainingSeats } from '../mock_data/member_modal';

const WARNING_ALERT_TITLE = 'You only have space for 2 more members in name';

describe('UserLimitNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTrialLink = () => wrapper.findByTestId('trial-link');
  const findUpgradeLink = () => wrapper.findByTestId('upgrade-link');

  const createComponent = (limitVariant, usersLimitDataset = {}, props = {}) => {
    wrapper = shallowMountExtended(UserLimitNotification, {
      propsData: {
        limitVariant,
        usersLimitDataset: {
          remainingSeats,
          freeUsersLimit,
          newTrialRegistrationPath: 'newTrialRegistrationPath',
          purchasePath: 'purchasePath',
          ...usersLimitDataset,
        },
        ...props,
      },
      provide: { name: 'name' },
      stubs: { GlSprintf },
    });
  };

  describe('when close to limit within a group', () => {
    it("renders user's limit notification", () => {
      createComponent(CLOSE_TO_LIMIT_VARIANT);

      const alert = findAlert();

      expect(alert.attributes('title')).toEqual(WARNING_ALERT_TITLE);

      expect(alert.text()).toContain('To get more members an owner of the group can');
    });
  });

  describe('when limit is reached', () => {
    it("renders user's limit notification", () => {
      createComponent(REACHED_LIMIT_VARIANT);

      const alert = findAlert();

      expect(alert.attributes('title')).toEqual("You've reached your 5 members limit for name");
      expect(alert.text()).toContain(
        'To invite new users to this top-level group, you must remove existing users.',
      );
    });
  });

  describe('tracking', () => {
    it.each([CLOSE_TO_LIMIT_VARIANT, REACHED_LIMIT_VARIANT])(
      `has tracking attributes for %j variant`,
      (variant) => {
        createComponent(variant);

        expect(findTrialLink().attributes('data-track-action')).toBe('click_link');
        expect(findTrialLink().attributes('data-track-label')).toBe(
          `start_trial_user_limit_notification_${variant}`,
        );
        expect(findUpgradeLink().attributes('data-track-action')).toBe('click_link');
        expect(findUpgradeLink().attributes('data-track-label')).toBe(
          `upgrade_user_limit_notification_${variant}`,
        );
      },
    );
  });
});
