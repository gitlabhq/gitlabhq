import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import InviteGroupNotification from '~/invite_members/components/invite_group_notification.vue';
import { GROUP_MODAL_TO_GROUP_ALERT_BODY } from '~/invite_members/constants';

describe('InviteGroupNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = shallowMountExtended(InviteGroupNotification, {
      provide: { freeUsersLimit: 5 },
      propsData: {
        name: 'name',
        notificationLink: '_notification_link_',
        notificationText: GROUP_MODAL_TO_GROUP_ALERT_BODY,
      },
      stubs: { GlSprintf },
    });
  };

  describe('when rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the correct props', () => {
      expect(findAlert().props()).toMatchObject({ variant: 'warning', dismissible: false });
    });

    it('shows the correct message', () => {
      const message = sprintf(GROUP_MODAL_TO_GROUP_ALERT_BODY, { count: 5 });

      expect(findAlert().text()).toMatchInterpolatedText(message);
    });

    it('has a help link', () => {
      expect(findLink().attributes('href')).toEqual('_notification_link_');
    });
  });
});
