import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserLimitNotification from '~/invite_members/components/user_limit_notification.vue';
import { REACHED_LIMIT_MESSAGE } from '~/invite_members/constants';
import { freeUsersLimit, membersCount } from '../mock_data/member_modal';

describe('UserLimitNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = (reachedLimit = false, usersLimitDataset = {}) => {
    wrapper = shallowMountExtended(UserLimitNotification, {
      propsData: {
        reachedLimit,
        usersLimitDataset: {
          freeUsersLimit,
          membersCount,
          newTrialRegistrationPath: 'newTrialRegistrationPath',
          purchasePath: 'purchasePath',
          ...usersLimitDataset,
        },
      },
      provide: { name: 'my group' },
      stubs: { GlSprintf },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when limit is not reached', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty block', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when close to limit', () => {
    beforeEach(() => {
      createComponent(false, { membersCount: 3 });
    });

    it("renders user's limit notification", () => {
      const alert = findAlert();

      expect(alert.attributes('title')).toEqual(
        'You only have space for 2 more members in my group',
      );

      expect(alert.text()).toEqual(
        'To get more members an owner of this namespace can start a trial or upgrade to a paid tier.',
      );
    });
  });

  describe('when limit is reached', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it("renders user's limit notification", () => {
      const alert = findAlert();

      expect(alert.attributes('title')).toEqual("You've reached your 5 members limit for my group");
      expect(alert.text()).toEqual(REACHED_LIMIT_MESSAGE);
    });
  });
});
