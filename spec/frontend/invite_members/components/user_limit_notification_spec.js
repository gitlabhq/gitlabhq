import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserLimitNotification from '~/invite_members/components/user_limit_notification.vue';

import {
  REACHED_LIMIT_MESSAGE,
  REACHED_LIMIT_UPGRADE_SUGGESTION_MESSAGE,
} from '~/invite_members/constants';

import { freeUsersLimit, membersCount } from '../mock_data/member_modal';

const WARNING_ALERT_TITLE = 'You only have space for 2 more members in name';

describe('UserLimitNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = (
    closeToLimit = false,
    reachedLimit = false,
    usersLimitDataset = {},
    props = {},
  ) => {
    wrapper = shallowMountExtended(UserLimitNotification, {
      propsData: {
        closeToLimit,
        reachedLimit,
        usersLimitDataset: {
          freeUsersLimit,
          membersCount,
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when limit is not reached', () => {
    it('renders empty block', () => {
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when close to limit within a personal namepace', () => {
    beforeEach(() => {
      createComponent(true, false, { membersCount: 3, userNamespace: true });
    });

    it('renders the limit for a personal namespace', () => {
      const alert = findAlert();

      expect(alert.attributes('title')).toEqual(WARNING_ALERT_TITLE);

      expect(alert.text()).toEqual(
        'To make more space, you can remove members who no longer need access.',
      );
    });
  });

  describe('when close to limit within a group', () => {
    it("renders user's limit notification", () => {
      createComponent(true, false, { membersCount: 3 });

      const alert = findAlert();

      expect(alert.attributes('title')).toEqual(WARNING_ALERT_TITLE);

      expect(alert.text()).toEqual(
        'To get more members an owner of the group can start a trial or upgrade to a paid tier.',
      );
    });
  });

  describe('when limit is reached', () => {
    it("renders user's limit notification", () => {
      createComponent(true, true);

      const alert = findAlert();

      expect(alert.attributes('title')).toEqual("You've reached your 5 members limit for name");
      expect(alert.text()).toEqual(REACHED_LIMIT_UPGRADE_SUGGESTION_MESSAGE);
    });

    describe('when free user namespace', () => {
      it("renders user's limit notification", () => {
        createComponent(true, true, { userNamespace: true });

        const alert = findAlert();

        expect(alert.attributes('title')).toEqual(
          "You've reached your 5 members limit for your personal projects",
        );

        expect(alert.text()).toEqual(REACHED_LIMIT_MESSAGE);
      });
    });
  });
});
