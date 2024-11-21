import { GlModal, GlSprintf, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Api from '~/api';
import InviteGroupsModal from '~/invite_members/components/invite_groups_modal.vue';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import ContentTransition from '~/invite_members/components/content_transition.vue';
import GroupSelect from '~/invite_members/components/group_select.vue';
import InviteGroupNotification from '~/invite_members/components/invite_group_notification.vue';
import { stubComponent } from 'helpers/stub_component';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';
import {
  GROUP_MODAL_TO_GROUP_ALERT_BODY,
  GROUP_MODAL_TO_GROUP_ALERT_LINK,
  GROUP_MODAL_TO_PROJECT_ALERT_BODY,
  GROUP_MODAL_TO_PROJECT_ALERT_LINK,
} from '~/invite_members/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import { propsData, sharedGroup } from '../mock_data/group_modal';

jest.mock('~/invite_members/utils/trigger_successful_invite_alert');

describe('InviteGroupsModal', () => {
  let wrapper;
  const mockToastShow = jest.fn();

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(InviteGroupsModal, {
      propsData: {
        ...propsData,
        ...props,
      },
      stubs: {
        InviteModalBase,
        ContentTransition,
        GlSprintf,
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  afterEach(() => {
    mockToastShow.mockClear();
  });

  const createInviteGroupToProjectWrapper = () => {
    createComponent({ isProject: true });
  };

  const createInviteGroupToGroupWrapper = () => {
    createComponent({ isProject: false });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findGroupSelect = () => wrapper.findComponent(GroupSelect);
  const findInviteGroupAlert = () => wrapper.findComponent(InviteGroupNotification);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const membersFormGroupInvalidFeedback = () =>
    findMembersFormGroup().attributes('invalid-feedback');
  const findBase = () => wrapper.findComponent(InviteModalBase);
  const triggerGroupSelect = (val) => findGroupSelect().vm.$emit('input', val);
  const hideModal = () => findModal().vm.$emit('hidden', { preventDefault: jest.fn() });

  const emitClickFromModal = (testId) => () =>
    wrapper.findByTestId(testId).vm.$emit('click', { preventDefault: jest.fn() });

  const clickInviteButton = emitClickFromModal('invite-modal-submit');
  const clickCancelButton = emitClickFromModal('invite-modal-cancel');

  describe('passes correct props to InviteModalBase', () => {
    it('set accessLevel', () => {
      createInviteGroupToProjectWrapper();

      expect(findBase().props('accessLevels')).toMatchObject({
        validRoles: propsData.accessLevels,
      });
    });

    describe('when inviting a group to a project', () => {
      it('set accessExpirationHelpLink for projects', () => {
        createInviteGroupToProjectWrapper();

        expect(findBase().props('accessExpirationHelpLink')).toBe(
          helpPagePath('user/project/members/sharing_projects_groups', {
            anchor: 'invite-a-group-to-a-project',
          }),
        );
      });
    });

    describe('when inviting a group to a group', () => {
      it('set accessExpirationHelpLink for groups', () => {
        createInviteGroupToGroupWrapper();

        expect(findBase().props('accessExpirationHelpLink')).toBe(
          helpPagePath('user/project/members/sharing_projects_groups', {
            anchor: 'invite-a-group-to-a-group',
          }),
        );
      });
    });
  });

  describe('displaying the correct introText and form group description', () => {
    describe('when inviting to a project', () => {
      it('includes the correct type, and formatted intro text', () => {
        createInviteGroupToProjectWrapper();

        expect(findIntroText()).toBe("You're inviting a group to the test name project.");
      });
    });

    describe('when inviting to a group', () => {
      it('includes the correct type, and formatted intro text', () => {
        createInviteGroupToGroupWrapper();

        expect(findIntroText()).toBe("You're inviting a group to the test name group.");
      });
    });
  });

  describe('rendering the invite group notification', () => {
    it('shows the user limit notification alert when free user cap is enabled', () => {
      createComponent({ freeUserCapEnabled: true });

      expect(findInviteGroupAlert().exists()).toBe(true);
    });

    it('does not show the user limit notification alert', () => {
      createComponent();

      expect(findInviteGroupAlert().exists()).toBe(false);
    });

    it('shows the user limit notification alert with correct link and text for group', () => {
      createComponent({ freeUserCapEnabled: true });

      expect(findInviteGroupAlert().props()).toMatchObject({
        name: propsData.name,
        notificationText: GROUP_MODAL_TO_GROUP_ALERT_BODY,
        notificationLink: GROUP_MODAL_TO_GROUP_ALERT_LINK,
      });
    });

    it('shows the user limit notification alert with correct link and text for project', () => {
      createComponent({ freeUserCapEnabled: true, isProject: true });

      expect(findInviteGroupAlert().props()).toMatchObject({
        name: propsData.name,
        notificationText: GROUP_MODAL_TO_PROJECT_ALERT_BODY,
        notificationLink: GROUP_MODAL_TO_PROJECT_ALERT_LINK,
      });
    });
  });

  describe('submitting the invite form', () => {
    let apiResolve;
    let apiReject;
    const groupPostData = {
      group_id: sharedGroup.id,
      group_access: propsData.defaultAccessLevel,
      expires_at: undefined,
      format: 'json',
    };

    beforeEach(() => {
      createComponent();
      triggerGroupSelect(sharedGroup);

      jest.spyOn(Api, 'groupShareWithGroup').mockImplementation(
        () =>
          new Promise((resolve, reject) => {
            apiResolve = resolve;
            apiReject = reject;
          }),
      );

      clickInviteButton();
    });

    it('shows loading', () => {
      expect(findBase().props('isLoading')).toBe(true);
    });

    it('calls Api groupShareWithGroup with the correct params', () => {
      expect(Api.groupShareWithGroup).toHaveBeenCalledWith(propsData.id, groupPostData);
    });

    describe('when succeeds', () => {
      beforeEach(() => {
        apiResolve({ data: groupPostData });
      });

      it('hides loading', () => {
        expect(findBase().props('isLoading')).toBe(false);
      });

      it('has no error message', () => {
        expect(findBase().props('invalidFeedbackMessage')).toBe('');
      });

      it('displays the successful toastMessage', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Members were successfully added.', {
          onComplete: expect.any(Function),
        });
      });

      it('does not call displaySuccessfulInvitationAlert on mount', () => {
        expect(displaySuccessfulInvitationAlert).not.toHaveBeenCalled();
      });

      it('does not call reloadOnInvitationSuccess', () => {
        expect(reloadOnInvitationSuccess).not.toHaveBeenCalled();
      });
    });

    describe('when fails', () => {
      beforeEach(() => {
        apiReject({ response: { data: { success: false } } });
      });

      it('does not show the toast message on failure', () => {
        expect(mockToastShow).not.toHaveBeenCalled();
      });

      it('displays the generic error for http server error', () => {
        expect(membersFormGroupInvalidFeedback()).toBe('Something went wrong');
      });

      it.each`
        desc                                   | act
        ${'when the cancel button is clicked'} | ${clickCancelButton}
        ${'when the modal is hidden'}          | ${hideModal}
        ${'when invite button is clicked'}     | ${clickInviteButton}
        ${'when group input changes'}          | ${() => triggerGroupSelect(sharedGroup)}
      `('clears the error, $desc', async ({ act }) => {
        act();

        await nextTick();

        expect(membersFormGroupInvalidFeedback()).toBe('');
      });
    });
  });

  describe('submitting the invite form with reloadPageOnSubmit set true', () => {
    const groupPostData = {
      group_id: sharedGroup.id,
      group_access: propsData.defaultAccessLevel,
      expires_at: undefined,
      member_role_id: null,
      format: 'json',
    };

    beforeEach(() => {
      createComponent({ reloadPageOnSubmit: true });
      triggerGroupSelect(sharedGroup);

      jest.spyOn(Api, 'groupShareWithGroup').mockResolvedValue({ data: groupPostData });

      clickInviteButton();
    });

    describe('when succeeds', () => {
      it('calls displaySuccessfulInvitationAlert on mount', () => {
        expect(displaySuccessfulInvitationAlert).toHaveBeenCalled();
      });

      it('calls reloadOnInvitationSuccess', () => {
        expect(reloadOnInvitationSuccess).toHaveBeenCalled();
      });

      it('does not show the toast message on failure', () => {
        expect(mockToastShow).not.toHaveBeenCalled();
      });
    });
  });

  describe('when group select emits an error event', () => {
    it('displays error alert', async () => {
      createComponent();

      findGroupSelect().vm.$emit('error', GroupSelect.i18n.errorMessage);
      await nextTick();

      expect(wrapper.findComponent(GlAlert).text()).toBe(GroupSelect.i18n.errorMessage);
    });
  });

  it('renders `GroupSelect` component and passes correct props', () => {
    createComponent({ isProject: true });

    expect(findGroupSelect().props()).toStrictEqual({
      selectedGroup: {},
      groupsFilter: 'all',
      isProject: true,
      sourceId: '1',
      parentGroupId: null,
      invalidGroups: [],
    });
  });
});
