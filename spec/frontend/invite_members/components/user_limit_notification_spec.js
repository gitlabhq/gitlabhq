import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserLimitNotification from '~/invite_members/components/user_limit_notification.vue';

describe('UserLimitNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = (providers = {}) => {
    wrapper = shallowMountExtended(UserLimitNotification, {
      provide: {
        name: 'my group',
        newTrialRegistrationPath: 'newTrialRegistrationPath',
        purchasePath: 'purchasePath',
        freeUsersLimit: 5,
        membersCount: 1,
        ...providers,
      },
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
      createComponent({ membersCount: 3 });
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
      createComponent({ membersCount: 5 });
    });

    it("renders user's limit notification", () => {
      const alert = findAlert();

      expect(alert.attributes('title')).toEqual("You've reached your 5 members limit for my group");

      expect(alert.text()).toEqual(
        'New members will be unable to participate. You can manage your members by removing ones you no longer need. To get more members an owner of this namespace can start a trial or upgrade to a paid tier.',
      );
    });
  });
});
