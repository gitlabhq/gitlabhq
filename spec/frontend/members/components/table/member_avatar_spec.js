import { shallowMount } from '@vue/test-utils';
import GroupAvatar from '~/members/components/avatars/group_avatar.vue';
import InviteAvatar from '~/members/components/avatars/invite_avatar.vue';
import UserAvatar from '~/members/components/avatars/user_avatar.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import { member as memberMock, group, invite, accessRequest } from '../../mock_data';

describe('MemberList', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(MemberAvatar, {
      propsData: {
        isCurrentUser: false,
        ...propsData,
      },
    });
  };

  it.each`
    memberType                         | member           | expectedComponent | expectedComponentName
    ${MEMBERS_TAB_TYPES.user}          | ${memberMock}    | ${UserAvatar}     | ${'UserAvatar'}
    ${MEMBERS_TAB_TYPES.group}         | ${group}         | ${GroupAvatar}    | ${'GroupAvatar'}
    ${MEMBERS_TAB_TYPES.invite}        | ${invite}        | ${InviteAvatar}   | ${'InviteAvatar'}
    ${MEMBERS_TAB_TYPES.accessRequest} | ${accessRequest} | ${UserAvatar}     | ${'UserAvatar'}
  `(
    'renders $expectedComponentName when `memberType` is $memberType',
    ({ memberType, member, expectedComponent }) => {
      createComponent({ memberType, member });

      expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
    },
  );
});
