import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import InviteGroupNotification from '~/invite_members/components/invite_group_notification.vue';
import { GROUP_MODAL_ALERT_BODY } from '~/invite_members/constants';

describe('InviteGroupNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = shallowMountExtended(InviteGroupNotification, {
      provide: { freeUsersLimit: 5 },
      propsData: { name: 'name' },
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
      const message = sprintf(GROUP_MODAL_ALERT_BODY, { count: 5 });

      expect(findAlert().text()).toMatchInterpolatedText(message);
    });

    it('has a help link', () => {
      expect(findLink().attributes('href')).toEqual(
        'https://docs.gitlab.com/ee/user/group/manage.html#share-a-group-with-another-group',
      );
    });
  });
});
