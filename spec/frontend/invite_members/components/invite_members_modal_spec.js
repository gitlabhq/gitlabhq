import { shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem, GlDatepicker, GlSprintf, GlLink, GlModal } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';

const id = '1';
const name = 'testgroup';
const isProject = false;
const accessLevels = { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 };
const defaultAccessLevel = '10';
const helpLink = 'https://example.com';

const user1 = { id: 1, name: 'Name One', username: 'one_1', avatar_url: '' };
const user2 = { id: 2, name: 'Name Two', username: 'one_2', avatar_url: '' };
const user3 = {
  id: 'user-defined-token',
  name: 'email@example.com',
  username: 'one_2',
  avatar_url: '',
};

const createComponent = (data = {}) => {
  return shallowMount(InviteMembersModal, {
    propsData: {
      id,
      name,
      isProject,
      accessLevels,
      defaultAccessLevel,
      helpLink,
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
    },
  });
};

describe('InviteMembersModal', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownItems = () => findDropdown().findAll(GlDropdownItem);
  const findDatepicker = () => wrapper.find(GlDatepicker);
  const findLink = () => wrapper.find(GlLink);
  const findCancelButton = () => wrapper.find({ ref: 'cancelButton' });
  const findInviteButton = () => wrapper.find({ ref: 'inviteButton' });
  const clickInviteButton = () => findInviteButton().vm.$emit('click');

  describe('rendering the modal', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.find(GlModal).props('title')).toBe('Invite team members');
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

  describe('submitting the invite form', () => {
    const apiErrorMessage = 'Member already exists';

    describe('when inviting an existing user to group by user ID', () => {
      const postData = {
        user_id: '1',
        access_level: '10',
        expires_at: undefined,
        format: 'json',
      };

      describe('when invites are sent successfully', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user1] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');

          clickInviteButton();
        });

        it('calls Api addGroupMembersByUserId with the correct params', () => {
          expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(id, postData);
        });

        it('displays the successful toastMessage', () => {
          expect(wrapper.vm.showToastMessageSuccess).toHaveBeenCalled();
        });
      });

      describe('when the invite received an api error message', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user1] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest
            .spyOn(Api, 'addGroupMembersByUserId')
            .mockRejectedValue({ response: { data: { message: apiErrorMessage } } });
          jest.spyOn(wrapper.vm, 'showToastMessageError');

          clickInviteButton();
        });

        it('displays the apiErrorMessage in the toastMessage', async () => {
          await waitForPromises();

          expect(wrapper.vm.showToastMessageError).toHaveBeenCalledWith({
            response: { data: { message: apiErrorMessage } },
          });
        });
      });

      describe('when any invite failed for any other reason', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user1, user2] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest
            .spyOn(Api, 'addGroupMembersByUserId')
            .mockRejectedValue({ response: { data: { success: false } } });
          jest.spyOn(wrapper.vm, 'showToastMessageError');

          clickInviteButton();
        });

        it('displays the generic error toastMessage', async () => {
          await waitForPromises();

          expect(wrapper.vm.showToastMessageError).toHaveBeenCalled();
        });
      });
    });

    describe('when inviting a new user by email address', () => {
      const postData = {
        access_level: '10',
        expires_at: undefined,
        email: 'email@example.com',
        format: 'json',
      };

      describe('when invites are sent successfully', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user3] });

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

      describe('when any invite failed for any reason', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user1, user2] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest
            .spyOn(Api, 'addGroupMembersByUserId')
            .mockRejectedValue({ response: { data: { success: false } } });
          jest.spyOn(wrapper.vm, 'showToastMessageError');

          clickInviteButton();
        });

        it('displays the generic error toastMessage', async () => {
          await waitForPromises();

          expect(wrapper.vm.showToastMessageError).toHaveBeenCalled();
        });
      });
    });

    describe('when inviting members and non-members in same click', () => {
      const postData = {
        access_level: '10',
        expires_at: undefined,
        format: 'json',
      };

      const emailPostData = { ...postData, email: 'email@example.com' };
      const idPostData = { ...postData, user_id: '1' };

      describe('when invites are sent successfully', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user1, user3] });

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({ data: postData });
          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
          jest.spyOn(wrapper.vm, 'showToastMessageSuccess');

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

      describe('when any invite failed for any reason', () => {
        beforeEach(() => {
          wrapper = createComponent({ newUsersToInvite: [user1, user3] });

          wrapper.vm.$toast = { show: jest.fn() };

          jest
            .spyOn(Api, 'inviteGroupMembersByEmail')
            .mockRejectedValue({ response: { data: { success: false } } });

          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
          jest.spyOn(wrapper.vm, 'showToastMessageError');

          clickInviteButton();
        });

        it('displays the generic error toastMessage', async () => {
          await waitForPromises();

          expect(wrapper.vm.showToastMessageError).toHaveBeenCalled();
        });
      });
    });
  });
});
