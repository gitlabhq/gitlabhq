import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import ModalConfetti from '~/invite_members/components/confetti.vue';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import {
  INVITE_MEMBERS_FOR_TASK,
  MEMBERS_MODAL_CELEBRATE_INTRO,
  MEMBERS_MODAL_CELEBRATE_TITLE,
  MEMBERS_PLACEHOLDER,
  MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT,
  LEARN_GITLAB,
} from '~/invite_members/constants';
import eventHub from '~/invite_members/event_hub';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import { getParameterValues } from '~/lib/utils/url_utility';
import { apiPaths, membersApiResponse, invitationsApiResponse } from '../mock_data/api_responses';
import {
  propsData,
  inviteSource,
  newProjectPath,
  user1,
  user2,
  user3,
  user4,
  GlEmoji,
} from '../mock_data/member_modal';

jest.mock('~/experimentation/experiment_tracking');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterValues: jest.fn(() => []),
}));

describe('InviteMembersModal', () => {
  let wrapper;
  let mock;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(InviteMembersModal, {
      provide: {
        newProjectPath,
      },
      propsData: {
        ...propsData,
        ...props,
      },
      stubs: {
        InviteModalBase,
        GlSprintf,
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        GlEmoji,
      },
    });
  };

  const createInviteMembersToProjectWrapper = () => {
    createComponent({ isProject: true });
  };

  const createInviteMembersToGroupWrapper = () => {
    createComponent({ isProject: false });
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

  const findBase = () => wrapper.findComponent(InviteModalBase);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findInviteButton = () => wrapper.findByTestId('invite-button');
  const clickInviteButton = () => findInviteButton().vm.$emit('click');
  const clickCancelButton = () => findCancelButton().vm.$emit('click');
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const membersFormGroupInvalidFeedback = () =>
    findMembersFormGroup().attributes('invalid-feedback');
  const membersFormGroupDescription = () => findMembersFormGroup().attributes('description');
  const findMembersSelect = () => wrapper.findComponent(MembersTokenSelect);
  const findTasksToBeDone = () => wrapper.findByTestId('invite-members-modal-tasks-to-be-done');
  const findTasks = () => wrapper.findByTestId('invite-members-modal-tasks');
  const findProjectSelect = () => wrapper.findByTestId('invite-members-modal-project-select');
  const findNoProjectsAlert = () => wrapper.findByTestId('invite-members-modal-no-projects-alert');
  const findCelebrationEmoji = () => wrapper.findComponent(GlEmoji);
  const triggerOpenModal = async ({ mode = 'default', source }) => {
    eventHub.$emit('openModal', { mode, source });
    await nextTick();
  };
  const triggerMembersTokenSelect = async (val) => {
    findMembersSelect().vm.$emit('input', val);
    await nextTick();
  };
  const triggerTasks = async (val) => {
    findTasks().vm.$emit('input', val);
    await nextTick();
  };
  const triggerAccessLevel = async (val) => {
    findBase().vm.$emit('access-level', val);
    await nextTick();
  };

  describe('rendering the tasks to be done', () => {
    const setupComponent = async (props = {}, urlParameter = ['invite_members_for_task']) => {
      getParameterValues.mockImplementation(() => urlParameter);
      createComponent(props);

      await triggerAccessLevel(30);
    };

    const setupComponentWithTasks = async (...args) => {
      await setupComponent(...args);
      await triggerTasks(['ci', 'code']);
    };

    afterAll(() => {
      getParameterValues.mockImplementation(() => []);
    });

    it('renders the tasks to be done', async () => {
      await setupComponent();

      expect(findTasksToBeDone().exists()).toBe(true);
    });

    describe('when the selected access level is lower than 30', () => {
      it('does not render the tasks to be done', async () => {
        await setupComponent();
        await triggerAccessLevel(20);

        expect(findTasksToBeDone().exists()).toBe(false);
      });
    });

    describe('when the url does not contain the parameter `open_modal=invite_members_for_task`', () => {
      it('does not render the tasks to be done', async () => {
        await setupComponent({}, []);

        expect(findTasksToBeDone().exists()).toBe(false);
      });

      describe('when opened from the Learn GitLab page', () => {
        it('does render the tasks to be done', async () => {
          await setupComponent({}, []);
          await triggerOpenModal({ source: LEARN_GITLAB });

          expect(findTasksToBeDone().exists()).toBe(true);
        });
      });
    });

    describe('rendering the tasks', () => {
      it('renders the tasks', async () => {
        await setupComponent();

        expect(findTasks().exists()).toBe(true);
      });

      it('does not render an alert', async () => {
        await setupComponent();

        expect(findNoProjectsAlert().exists()).toBe(false);
      });

      describe('when there are no projects passed in the data', () => {
        it('does not render the tasks', async () => {
          await setupComponent({ projects: [] });

          expect(findTasks().exists()).toBe(false);
        });

        it('renders an alert with a link to the new projects path', async () => {
          await setupComponent({ projects: [] });

          expect(findNoProjectsAlert().exists()).toBe(true);
          expect(findNoProjectsAlert().findComponent(GlLink).attributes('href')).toBe(
            newProjectPath,
          );
        });
      });
    });

    describe('rendering the project dropdown', () => {
      it('renders the project select', async () => {
        await setupComponentWithTasks();

        expect(findProjectSelect().exists()).toBe(true);
      });

      describe('when the modal is shown for a project', () => {
        it('does not render the project select', async () => {
          await setupComponentWithTasks({ isProject: true });

          expect(findProjectSelect().exists()).toBe(false);
        });
      });

      describe('when no tasks are selected', () => {
        it('does not render the project select', async () => {
          await setupComponent();

          expect(findProjectSelect().exists()).toBe(false);
        });
      });
    });

    describe('tracking events', () => {
      it('tracks the view for invite_members_for_task', async () => {
        await setupComponentWithTasks();

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_FOR_TASK.name);
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          INVITE_MEMBERS_FOR_TASK.view,
        );
      });

      it('tracks the submit for invite_members_for_task', async () => {
        await setupComponentWithTasks();
        clickInviteButton();

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_FOR_TASK.name, {
          label: 'selected_tasks_to_be_done',
          property: 'ci,code',
        });
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          INVITE_MEMBERS_FOR_TASK.submit,
        );
      });
    });
  });

  describe('displaying the correct introText and form group description', () => {
    describe('when inviting to a project', () => {
      describe('when inviting members', () => {
        beforeEach(() => {
          createInviteMembersToProjectWrapper();
        });

        it('renders the modal without confetti', () => {
          expect(wrapper.findComponent(ModalConfetti).exists()).toBe(false);
        });

        it('includes the correct invitee, type, and formatted name', () => {
          expect(findIntroText()).toBe("You're inviting members to the test name project.");
          expect(findCelebrationEmoji().exists()).toBe(false);
          expect(membersFormGroupDescription()).toBe(MEMBERS_PLACEHOLDER);
        });
      });

      describe('when inviting members with celebration', () => {
        beforeEach(async () => {
          createComponent({ isProject: true });
          await triggerOpenModal({ mode: 'celebrate' });
        });

        it('renders the modal with confetti', () => {
          expect(wrapper.findComponent(ModalConfetti).exists()).toBe(true);
        });

        it('renders the modal with the correct title', () => {
          expect(wrapper.findComponent(GlModal).props('title')).toBe(MEMBERS_MODAL_CELEBRATE_TITLE);
        });

        it('includes the correct celebration text and emoji', () => {
          expect(findIntroText()).toBe(
            `${MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT}  ${MEMBERS_MODAL_CELEBRATE_INTRO}`,
          );
          expect(findCelebrationEmoji().exists()).toBe(true);
          expect(membersFormGroupDescription()).toBe(MEMBERS_PLACEHOLDER);
        });
      });
    });

    describe('when inviting to a group', () => {
      it('includes the correct invitee, type, and formatted name', () => {
        createInviteMembersToGroupWrapper();

        expect(findIntroText()).toBe("You're inviting members to the test name group.");
        expect(membersFormGroupDescription()).toBe(MEMBERS_PLACEHOLDER);
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
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.";
    const expectedSyntaxError = 'email contains an invalid email address';

    describe('when inviting an existing user to group by user ID', () => {
      const postData = {
        user_id: '1,2',
        access_level: propsData.defaultAccessLevel,
        expires_at: undefined,
        invite_source: inviteSource,
        format: 'json',
        tasks_to_be_done: [],
        tasks_project_id: '',
      };

      describe('when member is added successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user1, user2]);

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('sets isLoading on the Invite button when it is clicked', () => {
            expect(findInviteButton().props('loading')).toBe(true);
          });

          it('calls Api addGroupMembersByUserId with the correct params', () => {
            expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(propsData.id, postData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
          });
        });

        describe('when opened from a Learn GitLab page', () => {
          it('emits the `showSuccessfulInvitationsAlert` event', async () => {
            await triggerOpenModal({ source: LEARN_GITLAB });

            jest.spyOn(eventHub, '$emit').mockImplementation();

            clickInviteButton();

            await waitForPromises();

            expect(eventHub.$emit).toHaveBeenCalledWith('showSuccessfulInvitationsAlert');
          });
        });
      });

      describe('when member is not added successfully', () => {
        beforeEach(async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user1]);
        });

        it('displays "Member already exists" api message for http status conflict', async () => {
          mockMembersApi(httpStatus.CONFLICT, membersApiResponse.MEMBER_ALREADY_EXISTS);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Member already exists');
          expect(findMembersSelect().props('validationState')).toBe(false);
          expect(findInviteButton().props('loading')).toBe(false);
        });

        describe('clearing the invalid state and message', () => {
          beforeEach(async () => {
            mockMembersApi(httpStatus.CONFLICT, membersApiResponse.MEMBER_ALREADY_EXISTS);

            clickInviteButton();

            await waitForPromises();
          });

          it('clears the error when the list of members to invite is cleared', async () => {
            expect(membersFormGroupInvalidFeedback()).toBe('Member already exists');
            expect(findMembersSelect().props('validationState')).toBe(false);

            findMembersSelect().vm.$emit('clear');

            await nextTick();

            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('validationState')).not.toBe(false);
          });

          it('clears the error when the cancel button is clicked', async () => {
            clickCancelButton();

            await nextTick();

            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('validationState')).not.toBe(false);
          });

          it('clears the error when the modal is hidden', async () => {
            wrapper.findComponent(GlModal).vm.$emit('hide');

            await nextTick();

            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('validationState')).not.toBe(false);
          });
        });

        it('clears the invalid state and message once the list of members to invite is cleared', async () => {
          mockMembersApi(httpStatus.CONFLICT, membersApiResponse.MEMBER_ALREADY_EXISTS);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Member already exists');
          expect(findMembersSelect().props('validationState')).toBe(false);
          expect(findInviteButton().props('loading')).toBe(false);

          findMembersSelect().vm.$emit('clear');

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('validationState')).toBe(null);
          expect(findInviteButton().props('loading')).toBe(false);
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
            "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
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
        access_level: propsData.defaultAccessLevel,
        expires_at: undefined,
        email: 'email@example.com',
        invite_source: inviteSource,
        tasks_to_be_done: [],
        tasks_project_id: '',
        format: 'json',
      };

      describe('when invites are sent successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user3]);

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembersByEmail with the correct params', () => {
            expect(Api.inviteGroupMembersByEmail).toHaveBeenCalledWith(propsData.id, postData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
          });
        });
      });

      describe('when invites are not sent successfully', () => {
        beforeEach(async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user3]);
        });

        it('displays the api error for invalid email syntax', async () => {
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('validationState')).toBe(false);
          expect(findInviteButton().props('loading')).toBe(false);
        });

        it('displays the restricted email error when restricted email is invited', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toContain(expectedEmailRestrictedError);
          expect(findMembersSelect().props('validationState')).toBe(false);
          expect(findInviteButton().props('loading')).toBe(false);
        });

        it('displays the successful toast message when email has already been invited', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_TAKEN);
          wrapper.vm.$toast = { show: jest.fn() };

          clickInviteButton();

          await waitForPromises();

          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
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

          await triggerMembersTokenSelect([user3, user4]);
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
        access_level: propsData.defaultAccessLevel,
        expires_at: undefined,
        invite_source: inviteSource,
        format: 'json',
        tasks_to_be_done: [],
        tasks_project_id: '',
      };

      const emailPostData = { ...postData, email: 'email@example.com' };
      const idPostData = { ...postData, user_id: '1' };

      describe('when invites are sent successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user1, user3]);

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({ data: postData });
          jest.spyOn(Api, 'addGroupMembersByUserId').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembersByEmail with the correct params', () => {
            expect(Api.inviteGroupMembersByEmail).toHaveBeenCalledWith(propsData.id, emailPostData);
          });

          it('calls Api addGroupMembersByUserId with the correct params', () => {
            expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(propsData.id, idPostData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
          });
        });

        it('calls Apis with the invite source passed through to openModal', async () => {
          await triggerOpenModal({ source: '_invite_source_' });

          clickInviteButton();

          expect(Api.inviteGroupMembersByEmail).toHaveBeenCalledWith(propsData.id, {
            ...emailPostData,
            invite_source: '_invite_source_',
          });
          expect(Api.addGroupMembersByUserId).toHaveBeenCalledWith(propsData.id, {
            ...idPostData,
            invite_source: '_invite_source_',
          });
        });
      });

      describe('when any invite failed for any reason', () => {
        beforeEach(async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user1, user3]);

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

    describe('tracking', () => {
      beforeEach(async () => {
        createComponent();
        await triggerMembersTokenSelect([user3]);

        wrapper.vm.$toast = { show: jest.fn() };
        jest.spyOn(Api, 'inviteGroupMembersByEmail').mockResolvedValue({});
      });

      it('tracks the view for learn_gitlab source', () => {
        eventHub.$emit('openModal', { inviteeType: 'members', source: LEARN_GITLAB });

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_FOR_TASK.name);
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(LEARN_GITLAB);
      });
    });
  });
});
