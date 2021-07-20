import {
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlFormGroup,
  GlSprintf,
  GlLink,
  GlModal,
} from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import { INVITE_MEMBERS_IN_COMMENT } from '~/invite_members/constants';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import { apiPaths, membersApiResponse, invitationsApiResponse } from '../mock_data/api_responses';

let wrapper;
let mock;

jest.mock('~/experimentation/experiment_tracking');

const id = '1';
const name = 'test name';
const isProject = false;
const inviteeType = 'members';
const accessLevels = { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 };
const defaultAccessLevel = 10;
const inviteSource = 'unknown';
const helpLink = 'https://example.com';

const user1 = { id: 1, name: 'Name One', username: 'one_1', avatar_url: '' };
const user2 = { id: 2, name: 'Name Two', username: 'one_2', avatar_url: '' };
const user3 = {
  id: 'user-defined-token',
  name: 'email@example.com',
  username: 'one_2',
  avatar_url: '',
};
const user4 = {
  id: 'user-defined-token',
  name: 'email4@example.com',
  username: 'one_4',
  avatar_url: '',
};
const sharedGroup = { id: '981' };

const createComponent = (data = {}, props = {}) => {
  wrapper = shallowMountExtended(InviteMembersModal, {
    propsData: {
      id,
      name,
      isProject,
      inviteeType,
      accessLevels,
      defaultAccessLevel,
      helpLink,
      ...props,
    },
    data() {
      return data;
    },
    stubs: {
      GlModal: stubComponent(GlModal, {
        template:
          '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
      }),
      GlDropdown: true,
      GlDropdownItem: true,
      GlSprintf,
      GlFormGroup: stubComponent(GlFormGroup, {
        props: ['state', 'invalidFeedback'],
      }),
    },
  });
};

const createInviteMembersToProjectWrapper = () => {
  createComponent({ inviteeType: 'members' }, { isProject: true });
};

const createInviteMembersToGroupWrapper = () => {
  createComponent({ inviteeType: 'members' }, { isProject: false });
};

const createInviteGroupToProjectWrapper = () => {
  createComponent({ inviteeType: 'group' }, { isProject: true });
};

const createInviteGroupToGroupWrapper = () => {
  createComponent({ inviteeType: 'group' }, { isProject: false });
};

beforeEach(() => {
  gon.api_version = 'v4';
  mock = new MockAdapter(axios);
});

afterEach(() => {
  wrapper.destroy();
  wrapper = null;
  mock.restore();
});

describe('InviteMembersModal', () => {
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findLink = () => wrapper.findComponent(GlLink);
  const findIntroText = () => wrapper.find({ ref: 'introText' }).text();
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findInviteButton = () => wrapper.findByTestId('invite-button');
  const clickInviteButton = () => findInviteButton().vm.$emit('click');
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const membersFormGroupInvalidFeedback = () => findMembersFormGroup().props('invalidFeedback');
  const findMembersSelect = () => wrapper.findComponent(MembersTokenSelect);

  describe('rendering the modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe('Invite members');
    });

    it('renders the Cancel button text correctly', () => {
      expect(findCancelButton().text()).toBe('Cancel');
    });

    it('renders the Invite button text correctly', () => {
      expect(findInviteButton().text()).toBe('Invite');
    });

    describe('rendering the access levels dropdown', () => {
      it('sets the default dropdown text to the default access level name', () => {
        expect(findDropdown().attributes('text')).toBe('Guest');
      });

      it('renders dropdown items for each accessLevel', () => {
        expect(findDropdownItems()).toHaveLength(5);
      });
    });

    describe('rendering the help link', () => {
      it('renders the correct link', () => {
        expect(findLink().attributes('href')).toBe(helpLink);
      });
    });

    describe('rendering the access expiration date field', () => {
      it('renders the datepicker', () => {
        expect(findDatepicker()).toExist();
      });
    });
  });

  describe('displaying the correct introText', () => {
    describe('when inviting to a project', () => {
      describe('when inviting members', () => {
        it('includes the correct invitee, type, and formatted name', () => {
          createInviteMembersToProjectWrapper();

          expect(findIntroText()).toBe("You're inviting members to the test name project.");
        });
      });

      describe('when sharing with a group', () => {
        it('includes the correct invitee, type, and formatted name', () => {
          createInviteGroupToProjectWrapper();

          expect(findIntroText()).toBe("You're inviting a group to the test name project.");
        });
      });
    });

    describe('when inviting to a group', () => {
      describe('when inviting members', () => {
        it('includes the correct invitee, type, and formatted name', () => {
          createInviteMembersToGroupWrapper();

          expect(findIntroText()).toBe("You're inviting members to the test name group.");
        });
      });

      describe('when sharing with a group', () => {
        it('includes the correct invitee, type, and formatted name', () => {
          createInviteGroupToGroupWrapper();

          expect(findIntroText()).toBe("You're inviting a group to the test name group.");
        });
      });
    });
  });

  describe('submitting the invite form', () => {
    const mockMembersApi = (code, data) => {
      mock.onPost(apiPaths.GROUPS_MEMBERS).reply(code, data);
    };
    const mockInvitationsApi = (code, data) => {
      mock.onPost(apiPaths.GROUPS_INVITATIONS).reply(code, data);
    };

    const expectedEmailRestrictedError =
      "email 'email@example.com' does not match the allowed domains: example1.org";
    const expectedSyntaxError = 'email contains an invalid email address';

    describe('when inviting an existing user to group by user ID', () => {
      const postData = {
        user_id: '1,2',
        access_level: defaultAccessLevel,
        expires_at: undefined,
        invite_source: inviteSource,
        format: 'json',
      };

      describe('when member is added successfully', () => {
        beforeEach(() => {
          createComponent({ newUsersToInvite: [user1, user2] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');

          clickInviteButton();
        });

        it('calls Api addGroupMembersByUserId with the correct params', async () => {
          await waitForPromises;

          expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(id, postData);
        });

        it('displays the successful toastMessage', async () => {
          await waitForPromises;

          expect(wrapper.vm.showToastMessageSuccess).toHaveBeenCalled();
        });
      });

      describe('when member is not added successfully', () => {
        beforeEach(() => {
          createInviteMembersToGroupWrapper();

          wrapper.setData({ newUsersToInvite: [user1] });
        });

        it('displays "Member already exists" api message for http status conflict', async () => {
          mockMembersApi(httpStatus.CONFLICT, membersApiResponse.MEMBER_ALREADY_EXISTS);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Member already exists');
          expect(findMembersFormGroup().props('state')).toBe(false);
          expect(findMembersSelect().props('validationState')).toBe(false);
        });

        it('clears the invalid state and message once the list of members to invite is cleared', async () => {
          mockMembersApi(httpStatus.CONFLICT, membersApiResponse.MEMBER_ALREADY_EXISTS);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Member already exists');
          expect(findMembersFormGroup().props('state')).toBe(false);
          expect(findMembersSelect().props('validationState')).toBe(false);

          findMembersSelect().vm.$emit('clear');

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersFormGroup().props('state')).not.toBe(false);
          expect(findMembersSelect().props('validationState')).not.toBe(false);
        });

        it('displays the generic error for http server error', async () => {
          mockMembersApi(httpStatus.INTERNAL_SERVER_ERROR, 'Request failed with status code 500');

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Something went wrong');
        });

        it('displays the restricted user api message for response with bad request', async () => {
          mockMembersApi(httpStatus.BAD_REQUEST, membersApiResponse.SINGLE_USER_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedEmailRestrictedError);
        });

        it('displays the first part of the error when multiple existing users are restricted by email', async () => {
          mockMembersApi(httpStatus.CREATED, membersApiResponse.MULTIPLE_USERS_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(
            "root: User email 'admin@example.com' does not match the allowed domain of example2.com",
          );
          expect(findMembersSelect().props('validationState')).toBe(false);
        });

        it('displays an access_level error message received for the existing user', async () => {
          mockMembersApi(httpStatus.BAD_REQUEST, membersApiResponse.SINGLE_USER_ACCESS_LEVEL);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(
            'should be greater than or equal to Owner inherited membership from group Gitlab Org',
          );
          expect(findMembersSelect().props('validationState')).toBe(false);
        });
      });
    });

    describe('when inviting a new user by email address', () => {
      const postData = {
        access_level: defaultAccessLevel,
        expires_at: undefined,
        email: 'email@example.com',
        invite_source: inviteSource,
        format: 'json',
      };

      describe('when invites are sent successfully', () => {
        beforeEach(() => {
          createComponent({ newUsersToInvite: [user3] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({ data: postData });
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');

          clickInviteButton();
        });

        it('calls Api inviteGroupMembersByEmail with the correct params', () => {
          expect(Api.inviteGroupMembersByEmail).toHaveBeenCalledWith(id, postData);
        });

        it('displays the successful toastMessage', () => {
          expect(wrapper.vm.showToastMessageSuccess).toHaveBeenCalled();
        });
      });

      describe('when invites are not sent successfully', () => {
        beforeEach(() => {
          createInviteMembersToGroupWrapper();

          wrapper.setData({ newUsersToInvite: [user3] });
        });

        it('displays the api error for invalid email syntax', async () => {
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('validationState')).toBe(false);
        });

        it('displays the restricted email error when restricted email is invited', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toContain(expectedEmailRestrictedError);
          expect(findMembersSelect().props('validationState')).toBe(false);
        });

        it('displays the successful toast message when email has already been invited', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_TAKEN);
          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');

          clickInviteButton();

          await waitForPromises();

          expect(wrapper.vm.showToastMessageSuccess).toHaveBeenCalled();
          expect(findMembersSelect().props('validationState')).toBe(null);
        });

        it('displays the first error message when multiple emails return a restricted error message', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.MULTIPLE_EMAIL_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toContain(expectedEmailRestrictedError);
          expect(findMembersSelect().props('validationState')).toBe(false);
        });

        it('displays the invalid syntax error for bad request', async () => {
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.ERROR_EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('validationState')).toBe(false);
        });
      });

      describe('when multiple emails are invited at the same time', () => {
        it('displays the invalid syntax error if one of the emails is invalid', async () => {
          createInviteMembersToGroupWrapper();

          wrapper.setData({ newUsersToInvite: [user3, user4] });
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.ERROR_EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('validationState')).toBe(false);
        });
      });
    });

    describe('when inviting members and non-members in same click', () => {
      const postData = {
        access_level: defaultAccessLevel,
        expires_at: undefined,
        invite_source: inviteSource,
        format: 'json',
      };

      const emailPostData = { ...postData, email: 'email@example.com' };
      const idPostData = { ...postData, user_id: '1' };

      describe('when invites are sent successfully', () => {
        beforeEach(() => {
          createComponent({ newUsersToInvite: [user1, user3] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({ data: postData });
          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');
          jest.spyOn(wrapper.vm, 'trackInvite');
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembersByEmail with the correct params', () => {
            expect(Api.inviteGroupMembersByEmail).toHaveBeenCalledWith(id, emailPostData);
          });

          it('calls Api addGroupMembersByUserId with the correct params', () => {
            expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(id, idPostData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.showToastMessageSuccess).toHaveBeenCalled();
          });
        });

        it('calls Apis with the invite source passed through to openModal', () => {
          wrapper.vm.openModal({ inviteeType: 'members', source: '_invite_source_' });

          clickInviteButton();

          expect(Api.inviteGroupMembersByEmail).toHaveBeenCalledWith(id, {
            ...emailPostData,
            invite_source: '_invite_source_',
          });
          expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(id, {
            ...idPostData,
            invite_source: '_invite_source_',
          });
        });
      });

      describe('when any invite failed for any reason', () => {
        beforeEach(() => {
          createInviteMembersToGroupWrapper();

          wrapper.setData({ newUsersToInvite: [user1, user3] });

          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);
          mockMembersApi(httpStatus.OK, '200 OK');

          clickInviteButton();
        });

        it('displays the first error message', async () => {
          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
        });
      });
    });

    describe('when inviting a group to share', () => {
      describe('when sharing the group is successful', () => {
        const groupPostData = {
          group_id: sharedGroup.id,
          group_access: defaultAccessLevel,
          expires_at: undefined,
          format: 'json',
        };

        beforeEach(() => {
          createComponent({ groupToBeSharedWith: sharedGroup });

          wrapper.setData({ inviteeType: 'group' });
          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'groupShareWithGroup').mockResolvedValue({ data: groupPostData });
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');

          clickInviteButton();
        });

        it('calls Api groupShareWithGroup with the correct params', () => {
          expect(Api.groupShareWithGroup).toHaveBeenCalledWith(id, groupPostData);
        });

        it('displays the successful toastMessage', () => {
          expect(wrapper.vm.showToastMessageSuccess).toHaveBeenCalled();
        });
      });

      describe('when sharing the group fails', () => {
        beforeEach(() => {
          createComponent({ groupToBeSharedWith: sharedGroup });

          wrapper.setData({ inviteeType: 'group' });
          wrapper.vm.$toast = { show: jest.fn() };

          jest
            .spyOn(Api, 'groupShareWithGroup')
            .mockRejectedValue({ response: { data: { success: false } } });

          clickInviteButton();
        });

        it('displays the generic error message', async () => {
          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Something went wrong');
        });
      });
    });

    describe('tracking', () => {
      beforeEach(() => {
        createComponent({ newUsersToInvite: [user3] });

        wrapper.vm.$toast = { show: jest.fn() };
        jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({});
      });

      it('tracks the invite', () => {
        wrapper.vm.openModal({ inviteeType: 'members', source: INVITE_MEMBERS_IN_COMMENT });

        clickInviteButton();

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_IN_COMMENT);
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith('comment_invite_success');
      });

      it('does not track invite for unknown source', () => {
        wrapper.vm.openModal({ inviteeType: 'members', source: 'unknown' });

        clickInviteButton();

        expect(ExperimentTracking).not.toHaveBeenCalled();
      });

      it('does not track invite undefined source', () => {
        wrapper.vm.openModal({ inviteeType: 'members' });

        clickInviteButton();

        expect(ExperimentTracking).not.toHaveBeenCalled();
      });
    });
  });
});
