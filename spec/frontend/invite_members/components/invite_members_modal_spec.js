import { shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem, GlDatepicker, GlSprintf, GlLink } from '@gitlab/ui';
import Api from '~/api';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';

const id = '1';
const name = 'testgroup';
const isProject = false;
const accessLevels = { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 };
const defaultAccessLevel = '10';
const helpLink = 'https://example.com';

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
      'gl-modal': '<div><slot name="modal-footer"></slot><slot></slot></div>',
      'gl-dropdown': true,
      'gl-dropdown-item': true,
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

  describe('rendering the modal', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.attributes('title')).toBe('Invite team members');
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
    const postData = {
      user_id: '1',
      access_level: '10',
      expires_at: new Date(),
      format: 'json',
    };

    describe('when the invite was sent successfully', () => {
      beforeEach(() => {
        wrapper = createComponent();

        wrapper.vm.$toast = { show: jest.fn() };
        jest.spyOn(Api, 'inviteGroupMember').mockResolvedValue({ data: postData });

        wrapper.vm.submitForm(postData);
      });

      it('displays the successful toastMessage', () => {
        const toastMessageSuccessful = 'Members were successfully added';

        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
          toastMessageSuccessful,
          wrapper.vm.toastOptions,
        );
      });

      it('calls Api inviteGroupMember with the correct params', () => {
        expect(Api.inviteGroupMember).toHaveBeenCalledWith(id, postData);
      });
    });

    describe('when sending the invite for a single member returned an api error', () => {
      const apiErrorMessage = 'Members already exists';

      beforeEach(() => {
        wrapper = createComponent({ newUsersToInvite: '123' });

        wrapper.vm.$toast = { show: jest.fn() };
        jest
          .spyOn(Api, 'inviteGroupMember')
          .mockRejectedValue({ response: { data: { message: apiErrorMessage } } });

        findInviteButton().vm.$emit('click');
      });

      it('displays the api error message for the toastMessage', () => {
        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
          apiErrorMessage,
          wrapper.vm.toastOptions,
        );
      });
    });

    describe('when sending the invite for multiple members returned any error', () => {
      const genericErrorMessage = 'Some of the members could not be added';

      beforeEach(() => {
        wrapper = createComponent({ newUsersToInvite: '123' });

        wrapper.vm.$toast = { show: jest.fn() };
        jest
          .spyOn(Api, 'inviteGroupMember')
          .mockRejectedValue({ response: { data: { success: false } } });

        findInviteButton().vm.$emit('click');
      });

      it('displays the expected toastMessage', () => {
        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
          genericErrorMessage,
          wrapper.vm.toastOptions,
        );
      });
    });
  });
});
