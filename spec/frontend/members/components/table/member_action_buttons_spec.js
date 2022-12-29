import { shallowMount } from '@vue/test-utils';
import AccessRequestActionButtons from '~/members/components/action_buttons/access_request_action_buttons.vue';
import GroupActionButtons from '~/members/components/action_buttons/group_action_buttons.vue';
import InviteActionButtons from '~/members/components/action_buttons/invite_action_buttons.vue';
import UserActionDropdown from '~/members/components/action_dropdowns/user_action_dropdown.vue';
import MemberActionButtons from '~/members/components/table/member_action_buttons.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { member as memberMock, group, invite, accessRequest } from '../../mock_data';

describe('MemberActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(MemberActionButtons, {
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

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    memberType                    | member           | expectedComponent             | expectedComponentName
    ${MEMBER_TYPES.user}          | ${memberMock}    | ${UserActionDropdown}         | ${'UserActionDropdown'}
    ${MEMBER_TYPES.group}         | ${group}         | ${GroupActionButtons}         | ${'GroupActionButtons'}
    ${MEMBER_TYPES.invite}        | ${invite}        | ${InviteActionButtons}        | ${'InviteActionButtons'}
    ${MEMBER_TYPES.accessRequest} | ${accessRequest} | ${AccessRequestActionButtons} | ${'AccessRequestActionButtons'}
  `(
    'renders $expectedComponentName when `memberType` is $memberType',
    ({ memberType, member, expectedComponent }) => {
      createComponent({ memberType, member });

      expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
    },
  );
});
