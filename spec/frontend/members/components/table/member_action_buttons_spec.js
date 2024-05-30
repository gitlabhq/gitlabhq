import { shallowMount } from '@vue/test-utils';
import AccessRequestActionButtons from '~/members/components/action_buttons/access_request_action_buttons.vue';
import GroupActionButtons from '~/members/components/action_buttons/group_action_buttons.vue';
import InviteActionButtons from '~/members/components/action_buttons/invite_action_buttons.vue';
import UserActionDropdown from '~/members/components/action_dropdowns/user_action_dropdown.vue';
import MemberActions from '~/members/components/table/member_actions.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import { member as memberMock, group, invite, accessRequest } from '../../mock_data';

describe('MemberActions', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(MemberActions, {
      propsData: {
        isCurrentUser: false,
        isInvitedUser: false,
        permissions: {
          canRemove: true,
        },
        ...propsData,
      },
    });
  };

  it.each`
    memberType                         | member           | expectedComponent             | expectedComponentName
    ${MEMBERS_TAB_TYPES.user}          | ${memberMock}    | ${UserActionDropdown}         | ${'UserActionDropdown'}
    ${MEMBERS_TAB_TYPES.group}         | ${group}         | ${GroupActionButtons}         | ${'GroupActionButtons'}
    ${MEMBERS_TAB_TYPES.invite}        | ${invite}        | ${InviteActionButtons}        | ${'InviteActionButtons'}
    ${MEMBERS_TAB_TYPES.accessRequest} | ${accessRequest} | ${AccessRequestActionButtons} | ${'AccessRequestActionButtons'}
  `(
    'renders $expectedComponentName when `memberType` is $memberType',
    ({ memberType, member, expectedComponent }) => {
      createComponent({ memberType, member });

      expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
    },
  );
});
