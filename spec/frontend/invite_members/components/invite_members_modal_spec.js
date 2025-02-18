import { GlModal, GlSprintf, GlFormGroup, GlCollapse, GlIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import ModalConfetti from '~/invite_members/components/confetti.vue';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import UserLimitNotification from '~/invite_members/components/user_limit_notification.vue';
import {
  MEMBERS_MODAL_CELEBRATE_INTRO,
  MEMBERS_MODAL_CELEBRATE_TITLE,
  MEMBERS_PLACEHOLDER,
  MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT,
  EXPANDED_ERRORS,
  EMPTY_INVITES_ALERT_TEXT,
  ON_CELEBRATION_TRACK_LABEL,
  INVITE_MEMBER_MODAL_TRACKING_CATEGORY,
  INVALID_FEEDBACK_MESSAGE_DEFAULT,
} from '~/invite_members/constants';
import eventHub from '~/invite_members/event_hub';
import ContentTransition from '~/invite_members/components/content_transition.vue';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_CREATED,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';
import { captureException } from '~/ci/runner/sentry_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { GROUPS_INVITATIONS_PATH, invitationsApiResponse } from '../mock_data/api_responses';
import {
  propsData,
  emailPostData,
  postData,
  singleUserPostData,
  newProjectPath,
  user1,
  user2,
  user3,
  user4,
  user5,
  user6,
  GlEmoji,
} from '../mock_data/member_modal';

jest.mock('~/invite_members/utils/trigger_successful_invite_alert');
jest.mock('~/experimentation/experiment_tracking');
jest.mock('~/ci/runner/sentry_utils');

describe('InviteMembersModal', () => {
  let wrapper;
  let mock;
  let trackingSpy;
  const showToast = jest.fn();

  const expectTracking = (action, label = undefined, property = undefined) =>
    expect(trackingSpy).toHaveBeenCalledWith(INVITE_MEMBER_MODAL_TRACKING_CATEGORY, action, {
      label,
      category: INVITE_MEMBER_MODAL_TRACKING_CATEGORY,
      property,
    });

  const createComponent = (props = {}, stubs = {}, provide = {}) => {
    wrapper = shallowMountExtended(InviteMembersModal, {
      provide: {
        newProjectPath,
        name: propsData.name,
        ...provide,
      },
      propsData: {
        usersLimitDataset: {},
        activeTrialDataset: {},
        fullPath: 'project',
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
        GlEmoji,
        ...stubs,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  const createInviteMembersToProjectWrapper = (
    usersLimitDataset = {},
    activeTrialDataset = {},
    stubs = {},
  ) => {
    createComponent({ usersLimitDataset, activeTrialDataset, isProject: true }, stubs);
  };

  const createInviteMembersToGroupWrapper = (
    usersLimitDataset = {},
    activeTrialDataset = {},
    stubs = {},
    provide = {},
    // eslint-disable-next-line max-params
  ) => {
    createComponent({ usersLimitDataset, activeTrialDataset, isProject: false }, stubs, provide);
  };

  beforeEach(() => {
    gon.api_version = 'v4';
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findBase = () => wrapper.findComponent(InviteModalBase);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findEmptyInvitesAlert = () => wrapper.findByTestId('empty-invites-alert');
  const findMemberErrorAlert = () => wrapper.findByTestId('alert-member-error');
  const findMoreInviteErrorsButton = () => wrapper.findByTestId('accordion-button');
  const findUserLimitAlert = () => wrapper.findComponent(UserLimitNotification);
  const findAccordion = () => wrapper.findComponent(GlCollapse);
  const findErrorsIcon = () => wrapper.findComponent(GlIcon);
  const findSeatOveragesAlert = () => wrapper.findByTestId('seat-overages-alert');
  const expectedErrorMessage = (index, errorType) => {
    const [username, message] = Object.entries(errorType.parsedMessage)[index];
    return `${username}: ${message}`;
  };
  const findActionButton = () => wrapper.findByTestId('invite-modal-submit');
  const findCancelButton = () => wrapper.findByTestId('invite-modal-cancel');
  const emitClickFromModal = (findButton) => () =>
    findButton().vm.$emit('click', { preventDefault: jest.fn() });

  const clickInviteButton = emitClickFromModal(findActionButton);
  const clickCancelButton = emitClickFromModal(findCancelButton);

  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const membersFormGroupInvalidFeedback = () =>
    findMembersFormGroup().attributes('invalid-feedback');
  const membersFormGroupDescription = () => findMembersFormGroup().attributes('description');
  const findMembersSelect = () => wrapper.findComponent(MembersTokenSelect);
  const findCelebrationEmoji = () => wrapper.findComponent(GlEmoji);
  const triggerOpenModal = async ({ mode = 'default', source } = {}) => {
    eventHub.$emit('openModal', { mode, source });
    await nextTick();
  };
  const triggerMembersTokenSelect = async (val) => {
    findMembersSelect().vm.$emit('input', val);
    await nextTick();
  };
  const removeMembersToken = async (val) => {
    findMembersSelect().vm.$emit('token-remove', val);
    await nextTick();
  };

  describe('passes correct props to InviteModalBase', () => {
    it('set defaultMemberRoleId', () => {
      createInviteMembersToProjectWrapper();

      expect(findBase().props('defaultMemberRoleId')).toBeNull();
    });

    it('set accessLevel', () => {
      createInviteMembersToProjectWrapper();

      expect(findBase().props('accessLevels')).toMatchObject({
        validRoles: propsData.accessLevels,
      });
    });

    describe('when inviting users to a project', () => {
      it('set accessExpirationHelpLink for projects', () => {
        createInviteMembersToProjectWrapper();

        expect(findBase().props('accessExpirationHelpLink')).toBe(
          helpPagePath('user/project/members/_index', { anchor: 'add-users-to-a-project' }),
        );
      });
    });

    describe('when inviting users to a group', () => {
      it('set accessExpirationHelpLink for groups', () => {
        createInviteMembersToGroupWrapper();

        expect(findBase().props('accessExpirationHelpLink')).toBe(
          helpPagePath('user/group/_index', { anchor: 'add-users-to-a-group' }),
        );
      });
    });
  });

  describe('rendering with tracking considerations', () => {
    describe('when inviting to a project', () => {
      describe('when inviting members', () => {
        beforeEach(() => {
          createInviteMembersToProjectWrapper();
        });

        it('renders the modal without confetti', () => {
          expect(wrapper.findComponent(ModalConfetti).exists()).toBe(false);
        });

        it('includes the correct invitee', () => {
          expect(findIntroText()).toBe("You're inviting members to the test name project.");
          expect(findCelebrationEmoji().exists()).toBe(false);
        });

        describe('members form group description', () => {
          it('renders correct description', () => {
            createInviteMembersToProjectWrapper({ GlFormGroup });
            expect(membersFormGroupDescription()).toContain(MEMBERS_PLACEHOLDER);
          });
        });
      });

      describe('when inviting members with celebration', () => {
        beforeEach(async () => {
          createInviteMembersToProjectWrapper();
          await triggerOpenModal({ mode: 'celebrate', source: ON_CELEBRATION_TRACK_LABEL });
        });

        it('renders the modal with confetti', () => {
          expect(wrapper.findComponent(ModalConfetti).exists()).toBe(true);
        });

        it('renders the modal with the correct title', () => {
          expect(findModal().props('title')).toBe(MEMBERS_MODAL_CELEBRATE_TITLE);
        });

        it('includes the correct celebration text and emoji', () => {
          expect(findIntroText()).toBe(
            `${MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT}  ${MEMBERS_MODAL_CELEBRATE_INTRO}`,
          );
          expect(findCelebrationEmoji().exists()).toBe(true);
        });

        describe('members form group description', () => {
          it('renders correct description', async () => {
            createInviteMembersToProjectWrapper({ GlFormGroup });
            await triggerOpenModal({ mode: 'celebrate' });

            expect(membersFormGroupDescription()).toContain(MEMBERS_PLACEHOLDER);
          });
        });

        describe('tracking', () => {
          it('tracks actions', async () => {
            trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

            await triggerOpenModal({ mode: 'celebrate', source: ON_CELEBRATION_TRACK_LABEL });

            expectTracking('render', ON_CELEBRATION_TRACK_LABEL);

            clickCancelButton();
            expectTracking('click_cancel', ON_CELEBRATION_TRACK_LABEL);

            findModal().vm.$emit('close');
            expectTracking('click_x', ON_CELEBRATION_TRACK_LABEL);

            unmockTracking();
          });
        });
      });
    });

    describe('when inviting to a group', () => {
      it('includes the correct invitee, type, and formatted name', () => {
        createInviteMembersToGroupWrapper();

        expect(findIntroText()).toBe("You're inviting members to the test name group.");
      });

      describe('members form group description', () => {
        it('renders correct description', () => {
          createInviteMembersToGroupWrapper({ GlFormGroup });
          expect(membersFormGroupDescription()).toContain(MEMBERS_PLACEHOLDER);
        });
      });
    });

    describe('tracking', () => {
      it.each`
        desc         | source                           | label
        ${'unknown'} | ${{}}                            | ${'unknown'}
        ${'known'}   | ${{ source: '_invite_source_' }} | ${'_invite_source_'}
      `('tracks actions with $desc source', async ({ source, label }) => {
        createInviteMembersToProjectWrapper();

        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        await triggerOpenModal(source);

        expectTracking('render', label);

        clickCancelButton();
        expectTracking('click_cancel', label);

        findModal().vm.$emit('close');
        expectTracking('click_x', label);

        unmockTracking();
      });
    });
  });

  describe('rendering the user limit notification', () => {
    it('shows the user limit notification alert when reached limit', () => {
      const usersLimitDataset = { alertVariant: 'reached' };

      createInviteMembersToProjectWrapper(usersLimitDataset);

      expect(findUserLimitAlert().exists()).toBe(true);
    });

    it('shows the user limit notification alert when close to dashboard limit', () => {
      const usersLimitDataset = { alertVariant: 'close' };

      createInviteMembersToProjectWrapper(usersLimitDataset);

      expect(findUserLimitAlert().exists()).toBe(true);
    });

    it('shows the user limit notification alert when :preview_free_user_cap is enabled', () => {
      const usersLimitDataset = { alertVariant: 'notification' };

      createInviteMembersToProjectWrapper(usersLimitDataset);

      expect(findUserLimitAlert().exists()).toBe(true);
    });

    it('does not show the user limit notification alert', () => {
      const usersLimitDataset = {};

      createInviteMembersToProjectWrapper(usersLimitDataset);

      expect(findUserLimitAlert().exists()).toBe(false);
    });
  });

  describe('submitting the invite form', () => {
    const mockInvitationsApi = (code, data) => {
      mock.onPost(GROUPS_INVITATIONS_PATH).reply(code, data);
    };

    const expectedSyntaxError = 'email contains an invalid email address';

    describe('when no invites have been entered in the form and then some are entered', () => {
      beforeEach(() => {
        createInviteMembersToGroupWrapper();
      });

      it('displays an error', async () => {
        clickInviteButton();

        await waitForPromises();

        expect(findEmptyInvitesAlert().text()).toBe(EMPTY_INVITES_ALERT_TEXT);
        expect(membersFormGroupInvalidFeedback()).toBe(MEMBERS_PLACEHOLDER);
        expect(findMembersSelect().props('exceptionState')).toBe(false);

        await triggerMembersTokenSelect([user1]);

        expect(membersFormGroupInvalidFeedback()).toBe('');
      });
    });

    describe('when inviting an existing user to group by user ID', () => {
      describe('when reloadOnSubmit is true', () => {
        beforeEach(async () => {
          createComponent({ reloadPageOnSubmit: true });
          await triggerMembersTokenSelect([user1, user2]);

          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: postData });
          clickInviteButton();
        });

        it('calls displaySuccessfulInvitationAlert on mount', () => {
          expect(displaySuccessfulInvitationAlert).toHaveBeenCalled();
        });

        it('calls reloadOnInvitationSuccess', () => {
          expect(reloadOnInvitationSuccess).toHaveBeenCalled();
        });

        it('does not show the toast message', () => {
          expect(showToast).not.toHaveBeenCalled();
        });
      });

      describe('when member is added successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user1, user2]);

          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembers with the correct params', () => {
            expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, postData);
          });

          it('displays the successful toastMessage', () => {
            expect(showToast).toHaveBeenCalledWith('Members were successfully added.');
          });

          it('does not call displaySuccessfulInvitationAlert on mount', () => {
            expect(displaySuccessfulInvitationAlert).not.toHaveBeenCalled();
          });

          it('does not call reloadOnInvitationSuccess', () => {
            expect(reloadOnInvitationSuccess).not.toHaveBeenCalled();
          });
        });
      });

      describe('when member is not added successfully', () => {
        beforeEach(async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user1]);
        });

        describe('clearing the invalid state and message', () => {
          beforeEach(async () => {
            mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.EMAIL_TAKEN);

            clickInviteButton();

            await waitForPromises();
          });

          it('clears the error when the list of members to invite is cleared', async () => {
            expect(findMemberErrorAlert().exists()).toBe(true);
            expect(findMemberErrorAlert().text()).toContain(
              Object.values(invitationsApiResponse.EMAIL_TAKEN.message)[0],
            );
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);

            findMembersSelect().vm.$emit('clear');

            await nextTick();

            expect(findMemberErrorAlert().exists()).toBe(false);
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });

          it('clears the error when the cancel button is clicked', async () => {
            clickCancelButton();

            await nextTick();

            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });

          it('clears the error when the modal is hidden', async () => {
            findModal().vm.$emit('hidden');

            await nextTick();

            expect(findMemberErrorAlert().exists()).toBe(false);
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });
        });

        it('displays the generic error for http server error', async () => {
          const SERVER_ERROR_MESSAGE = 'Request failed with status code 500';
          mockInvitationsApi(HTTP_STATUS_INTERNAL_SERVER_ERROR, SERVER_ERROR_MESSAGE);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Something went wrong');
          expect(findMembersSelect().props('exceptionState')).toBe(false);
          expect(captureException).toHaveBeenCalledWith({
            error: new Error(SERVER_ERROR_MESSAGE),
            component: wrapper.vm.$options.name,
          });
        });

        it('displays the restricted user api message for response with bad request', async () => {
          mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.EMAIL_RESTRICTED);

          await triggerMembersTokenSelect([user3]);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(0, invitationsApiResponse.EMAIL_RESTRICTED),
          );
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
        });

        it('displays all errors when there are multiple existing users that are restricted by email', async () => {
          mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.MULTIPLE_RESTRICTED);

          await triggerMembersTokenSelect([user3, user4, user5]);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(0, invitationsApiResponse.MULTIPLE_RESTRICTED),
          );
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(1, invitationsApiResponse.MULTIPLE_RESTRICTED),
          );
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(2, invitationsApiResponse.MULTIPLE_RESTRICTED),
          );
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
        });

        it('displays invite limit error message', async () => {
          mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.INVITE_LIMIT);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(
            invitationsApiResponse.INVITE_LIMIT.message,
          );
        });
      });
    });

    describe('when inviting a new user by email address', () => {
      describe('when invites are sent successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user3]);

          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: emailPostData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembers with the correct params', () => {
            expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, emailPostData);
          });

          it('displays the successful toastMessage', () => {
            expect(showToast).toHaveBeenCalledWith('Members were successfully added.');
          });

          it('does not call displaySuccessfulInvitationAlert on mount', () => {
            expect(displaySuccessfulInvitationAlert).not.toHaveBeenCalled();
          });

          it('does not call reloadOnInvitationSuccess', () => {
            expect(reloadOnInvitationSuccess).not.toHaveBeenCalled();
          });
        });
      });

      describe('when invites are not sent successfully', () => {
        describe('when api throws error', () => {
          beforeEach(async () => {
            jest.spyOn(axios, 'post').mockImplementation(() => {
              throw new Error();
            });

            createInviteMembersToGroupWrapper();

            await triggerMembersTokenSelect([user3]);
            clickInviteButton();
          });

          it('displays the default error message', () => {
            expect(membersFormGroupInvalidFeedback()).toBe(INVALID_FEEDBACK_MESSAGE_DEFAULT);
            expect(findMembersSelect().props('exceptionState')).toBe(false);
            expect(findActionButton().props('loading')).toBe(false);
          });
        });

        describe('when api rejects promise', () => {
          beforeEach(async () => {
            createInviteMembersToGroupWrapper();

            await triggerMembersTokenSelect([user3]);
          });

          it('displays the api error for invalid email syntax', async () => {
            mockInvitationsApi(HTTP_STATUS_BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);

            clickInviteButton();

            await waitForPromises();

            expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
            expect(findMembersSelect().props('exceptionState')).toBe(false);
            expect(findActionButton().props('loading')).toBe(false);
          });

          it('clears the error when the modal is hidden', async () => {
            mockInvitationsApi(HTTP_STATUS_BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);

            clickInviteButton();

            await waitForPromises();

            expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
            expect(findMembersSelect().props('exceptionState')).toBe(false);
            expect(findActionButton().props('loading')).toBe(false);

            findModal().vm.$emit('hidden');

            await nextTick();

            expect(findMemberErrorAlert().exists()).toBe(false);
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });

          it('displays the restricted email error when restricted email is invited', async () => {
            mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.EMAIL_RESTRICTED);

            clickInviteButton();

            await waitForPromises();

            expect(findMemberErrorAlert().exists()).toBe(true);
            expect(findMemberErrorAlert().text()).toContain(
              expectedErrorMessage(0, invitationsApiResponse.EMAIL_RESTRICTED),
            );
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
            expect(findActionButton().props('loading')).toBe(false);
          });

          it('displays all errors when there are multiple emails that return a restricted error message', async () => {
            mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.MULTIPLE_RESTRICTED);

            await triggerMembersTokenSelect([user3, user4, user5]);

            clickInviteButton();

            await waitForPromises();

            expect(findMemberErrorAlert().exists()).toBe(true);
            expect(findMemberErrorAlert().text()).toContain(
              expectedErrorMessage(0, invitationsApiResponse.MULTIPLE_RESTRICTED),
            );
            expect(findMemberErrorAlert().text()).toContain(
              expectedErrorMessage(1, invitationsApiResponse.MULTIPLE_RESTRICTED),
            );
            expect(findMemberErrorAlert().text()).toContain(
              expectedErrorMessage(2, invitationsApiResponse.MULTIPLE_RESTRICTED),
            );
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });

          it('displays the invalid syntax error for bad request', async () => {
            mockInvitationsApi(HTTP_STATUS_BAD_REQUEST, invitationsApiResponse.ERROR_EMAIL_INVALID);

            clickInviteButton();

            await waitForPromises();

            expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
            expect(findMembersSelect().props('exceptionState')).toBe(false);
          });

          it('does not call displaySuccessfulInvitationAlert on mount', () => {
            expect(displaySuccessfulInvitationAlert).not.toHaveBeenCalled();
          });

          it('does not call reloadOnInvitationSuccess', () => {
            expect(reloadOnInvitationSuccess).not.toHaveBeenCalled();
          });
        });
      });

      describe('when multiple emails are invited at the same time', () => {
        it('displays the invalid syntax error if one of the emails is invalid', async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user3, user4]);
          mockInvitationsApi(HTTP_STATUS_BAD_REQUEST, invitationsApiResponse.ERROR_EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('exceptionState')).toBe(false);
        });

        it('displays errors for multiple and allows clearing', async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user3, user4, user5, user6]);
          mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.EXPANDED_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().props('title')).toContain(
            "The following 4 members couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(0, invitationsApiResponse.EXPANDED_RESTRICTED),
          );
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(1, invitationsApiResponse.EXPANDED_RESTRICTED),
          );
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(2, invitationsApiResponse.EXPANDED_RESTRICTED),
          );
          expect(findMemberErrorAlert().text()).toContain(
            expectedErrorMessage(3, invitationsApiResponse.EXPANDED_RESTRICTED),
          );
          expect(findAccordion().exists()).toBe(true);
          expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
          expect(findErrorsIcon().attributes('class')).not.toContain('gl-rotate-180');
          expect(findAccordion().attributes('visible')).toBeUndefined();

          await findMoreInviteErrorsButton().vm.$emit('click');

          expect(findMoreInviteErrorsButton().text()).toContain(EXPANDED_ERRORS);
          expect(findErrorsIcon().attributes('class')).toContain('gl-rotate-180');
          expect(findAccordion().attributes('visible')).toBeDefined();

          await findMoreInviteErrorsButton().vm.$emit('click');

          expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
          expect(findAccordion().attributes('visible')).toBeUndefined();

          await removeMembersToken(user3);

          expect(findMoreInviteErrorsButton().text()).toContain('Show more (1)');
          expect(findMemberErrorAlert().props('title')).toContain(
            "The following 3 members couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).not.toContain(
            expectedErrorMessage(0, invitationsApiResponse.EXPANDED_RESTRICTED),
          );

          await removeMembersToken(user6);

          expect(findMoreInviteErrorsButton().exists()).toBe(false);
          expect(findMemberErrorAlert().props('title')).toContain(
            "The following 2 members couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).not.toContain(
            expectedErrorMessage(2, invitationsApiResponse.EXPANDED_RESTRICTED),
          );

          await removeMembersToken(user4);

          expect(findMemberErrorAlert().props('title')).toContain(
            "The following member couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).not.toContain(
            expectedErrorMessage(1, invitationsApiResponse.EXPANDED_RESTRICTED),
          );

          await removeMembersToken(user5);

          expect(findMemberErrorAlert().exists()).toBe(false);
        });
      });
    });

    describe('when inviting members and non-members in same click', () => {
      describe('when invites are sent successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user1, user3]);

          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: singleUserPostData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(async () => {
            await triggerOpenModal({ source: '_invite_source_' });

            clickInviteButton();
          });

          it('calls Api inviteGroupMembers with the correct params and invite source', () => {
            expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, {
              ...singleUserPostData,
              invite_source: '_invite_source_',
            });
          });

          it('displays the successful toastMessage', () => {
            expect(showToast).toHaveBeenCalledWith('Members were successfully added.');
          });

          it('does not call displaySuccessfulInvitationAlert on mount', () => {
            expect(displaySuccessfulInvitationAlert).not.toHaveBeenCalled();
          });

          it('does not call reloadOnInvitationSuccess', () => {
            expect(reloadOnInvitationSuccess).not.toHaveBeenCalled();
          });

          it('tracks successful invite when source is known', () => {
            expectTracking('invite_successful', '_invite_source_');

            unmockTracking();
          });
        });

        it('calls Apis without the invite source passed through to openModal', async () => {
          await triggerOpenModal();

          clickInviteButton();

          expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, singleUserPostData);
        });
      });
    });

    describe('blocked seat overage error notifications', () => {
      it('shows the notification alert when seat overage limit is reached and the purchase seats href is present', async () => {
        createInviteMembersToGroupWrapper({}, {}, {}, { addSeatsHref: 'url_to_add_seats' });
        await triggerMembersTokenSelect([user1]);
        mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.ERROR_SEAT_LIMIT_REACHED);
        clickInviteButton();
        await waitForPromises();

        expect(findSeatOveragesAlert().exists()).toBe(true);
      });

      it('does not show the notification alert when seat overage limit is reached and the purchase seats href is absent', async () => {
        createInviteMembersToGroupWrapper();
        await triggerMembersTokenSelect([user1]);
        mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.ERROR_SEAT_LIMIT_REACHED);
        clickInviteButton();
        await waitForPromises();

        expect(findSeatOveragesAlert().exists()).toBe(false);
      });

      describe('when hasBsoEnabled is true', () => {
        beforeEach(() => {
          createInviteMembersToGroupWrapper(
            {},
            {},
            {},
            { addSeatsHref: 'url_to_add_seats', hasBsoEnabled: true },
          );
        });

        it('shows the seat limit reached label for the primary button', async () => {
          await triggerMembersTokenSelect([user1]);
          mockInvitationsApi(HTTP_STATUS_CREATED, invitationsApiResponse.ERROR_SEAT_LIMIT_REACHED);
          clickInviteButton();
          await waitForPromises();

          expect(findSeatOveragesAlert().exists()).toBe(true);
          expect(findSeatOveragesAlert().props('primaryButtonText')).toBe('Learn how to add seats');
        });
      });
    });
  });
});
