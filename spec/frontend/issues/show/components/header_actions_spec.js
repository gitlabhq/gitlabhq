import Vue, { nextTick } from 'vue';
import { GlDropdownItem, GlLink, GlModal, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { STATUS_CLOSED, STATUS_OPEN, TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import HeaderActions from '~/issues/show/components/header_actions.vue';
import { ISSUE_STATE_EVENT_CLOSE, ISSUE_STATE_EVENT_REOPEN } from '~/issues/show/constants';
import issuesEventHub from '~/issues/show/event_hub';
import promoteToEpicMutation from '~/issues/show/queries/promote_to_epic.mutation.graphql';
import * as urlUtility from '~/lib/utils/url_utility';
import eventHub from '~/notes/event_hub';
import createStore from '~/notes/stores';
import createMockApollo from 'helpers/mock_apollo_helper';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import updateIssueMutation from '~/issues/show/queries/update_issue.mutation.graphql';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/alert');
jest.mock('~/issues/show/event_hub', () => ({ $emit: jest.fn() }));
jest.mock('~/vue_shared/plugins/global_toast');

describe('HeaderActions component', () => {
  let dispatchEventSpy;
  let wrapper;
  let visitUrlSpy;

  Vue.use(Vuex);
  Vue.use(VueApollo);

  const store = createStore();

  const defaultProps = {
    canCreateIssue: true,
    canDestroyIssue: true,
    canPromoteToEpic: true,
    canReopenIssue: true,
    canReportSpam: true,
    canUpdateIssue: true,
    iid: '32',
    isIssueAuthor: true,
    issuePath: 'gitlab-org/gitlab-test/-/issues/1',
    issueType: TYPE_ISSUE,
    newIssuePath: 'gitlab-org/gitlab-test/-/issues/new',
    projectPath: 'gitlab-org/gitlab-test',
    reportAbusePath: '-/abuse_reports/add_category',
    reportedUserId: 1,
    reportedFromUrl: 'http://localhost:/gitlab-org/-/issues/32',
    submitAsSpamPath: 'gitlab-org/gitlab-test/-/issues/32/submit_as_spam',
    issuableEmailAddress: null,
    fullPath: 'full-path',
  };

  const updateIssueMutationResponse = {
    data: {
      updateIssue: {
        errors: [],
        issuable: {
          id: 'gid://gitlab/Issue/511',
          state: STATUS_OPEN,
        },
      },
    },
  };

  const promoteToEpicMutationResponse = {
    data: {
      promoteToEpic: {
        errors: [],
        epic: {
          id: 'gid://gitlab/Epic/1',
          webPath: '/groups/gitlab-org/-/epics/1',
        },
      },
    },
  };

  const promoteToEpicMutationErrorResponse = {
    data: {
      promoteToEpic: {
        errors: ['The issue has already been promoted to an epic.'],
        epic: {},
      },
    },
  };

  const mockIssueReferenceData = {
    data: {
      workspace: {
        id: 'gid://gitlab/Project/7',
        issuable: {
          id: 'gid://gitlab/Issue/511',
          reference: 'flightjs/Flight#33',
          __typename: 'Issue',
        },
        __typename: 'Project',
      },
    },
  };

  const findToggleIssueStateButton = () => wrapper.find(`[data-testid="toggle-button"]`);
  const findEditButton = () => wrapper.find(`[data-testid="edit-button"]`);

  const findDropdownBy = (dataTestId) => wrapper.find(`[data-testid="${dataTestId}"]`);
  const findMobileDropdown = () => findDropdownBy('mobile-dropdown');
  const findDesktopDropdown = () => findDropdownBy('desktop-dropdown');
  const findMobileDropdownItems = () => findMobileDropdown().findAllComponents(GlDropdownItem);
  const findDesktopDropdownItems = () => findDesktopDropdown().findAllComponents(GlDropdownItem);
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findReportAbuseSelectorItem = () => wrapper.find(`[data-testid="report-abuse-item"]`);
  const findNotificationWidget = () => wrapper.find(`[data-testid="notification-toggle"]`);
  const findLockIssueWidget = () => wrapper.find(`[data-testid="lock-issue-toggle"]`);
  const findCopyRefenceDropdownItem = () => wrapper.find(`[data-testid="copy-reference"]`);
  const findCopyEmailItem = () => wrapper.find(`[data-testid="copy-email"]`);

  const findModal = () => wrapper.findComponent(GlModal);

  const findModalLinkAt = (index) => findModal().findAllComponents(GlLink).at(index);

  const issueReferenceSuccessHandler = jest.fn().mockResolvedValue(mockIssueReferenceData);
  const updateIssueMutationResponseHandler = jest
    .fn()
    .mockResolvedValue(updateIssueMutationResponse);
  const promoteToEpicMutationSuccessResponseHandler = jest
    .fn()
    .mockResolvedValue(promoteToEpicMutationResponse);
  const promoteToEpicMutationErrorHandler = jest
    .fn()
    .mockResolvedValue(promoteToEpicMutationErrorResponse);

  const mountComponent = ({
    props = {},
    issueState = STATUS_OPEN,
    blockedByIssues = [],
    movedMrSidebarEnabled = false,
    promoteToEpicHandler = promoteToEpicMutationSuccessResponseHandler,
  } = {}) => {
    store.dispatch('setNoteableData', {
      blocked_by_issues: blockedByIssues,
      state: issueState,
    });

    const handlers = [
      [issueReferenceQuery, issueReferenceSuccessHandler],
      [updateIssueMutation, updateIssueMutationResponseHandler],
      [promoteToEpicMutation, promoteToEpicHandler],
    ];

    return shallowMount(HeaderActions, {
      apolloProvider: createMockApollo(handlers),
      store,
      provide: {
        ...defaultProps,
        ...props,
        glFeatures: {
          movedMrSidebar: movedMrSidebarEnabled,
        },
      },
      stubs: {
        GlButton,
      },
    });
  };

  afterEach(() => {
    if (dispatchEventSpy) {
      dispatchEventSpy.mockRestore();
    }
    if (visitUrlSpy) {
      visitUrlSpy.mockRestore();
    }
  });

  describe.each`
    issueType
    ${TYPE_ISSUE}
    ${TYPE_INCIDENT}
  `('when issue type is $issueType', ({ issueType }) => {
    describe('close/reopen button', () => {
      describe.each`
        description                          | issueState       | buttonText               | newIssueState
        ${`when the ${issueType} is open`}   | ${STATUS_OPEN}   | ${`Close ${issueType}`}  | ${ISSUE_STATE_EVENT_CLOSE}
        ${`when the ${issueType} is closed`} | ${STATUS_CLOSED} | ${`Reopen ${issueType}`} | ${ISSUE_STATE_EVENT_REOPEN}
      `('$description', ({ issueState, buttonText, newIssueState }) => {
        beforeEach(() => {
          dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

          wrapper = mountComponent({
            props: { issueType },
            issueState,
          });
        });

        it(`has text "${buttonText}"`, () => {
          expect(findToggleIssueStateButton().text()).toBe(buttonText);
        });

        it('calls apollo mutation', () => {
          findToggleIssueStateButton().vm.$emit('click');

          expect(updateIssueMutationResponseHandler).toHaveBeenCalledWith({
            input: {
              iid: defaultProps.iid,
              projectPath: defaultProps.projectPath,
              stateEvent: newIssueState,
            },
          });
        });

        it('dispatches a custom event to update the issue page', async () => {
          findToggleIssueStateButton().vm.$emit('click');

          await waitForPromises();

          expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe.each`
      description           | isCloseIssueItemVisible | findDropdownItems           | findDropdown
      ${'mobile dropdown'}  | ${true}                 | ${findMobileDropdownItems}  | ${findMobileDropdown}
      ${'desktop dropdown'} | ${false}                | ${findDesktopDropdownItems} | ${findDesktopDropdown}
    `('$description', ({ isCloseIssueItemVisible, findDropdownItems, findDropdown }) => {
      describe.each`
        description                               | itemText                           | isItemVisible              | canUpdateIssue | canCreateIssue | isIssueAuthor | canReportSpam | canPromoteToEpic | canDestroyIssue
        ${`when user can update ${issueType}`}    | ${`Close ${issueType}`}            | ${isCloseIssueItemVisible} | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot update ${issueType}`} | ${`Close ${issueType}`}            | ${false}                   | ${false}       | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user can create ${issueType}`}    | ${`New related ${issueType}`}      | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot create ${issueType}`} | ${`New related ${issueType}`}      | ${false}                   | ${true}        | ${false}       | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user can promote to epic'}        | ${'Promote to epic'}               | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user cannot promote to epic'}     | ${'Promote to epic'}               | ${false}                   | ${true}        | ${true}        | ${true}       | ${true}       | ${false}         | ${true}
        ${'when user can report abuse'}           | ${'Report abuse to administrator'} | ${true}                    | ${true}        | ${true}        | ${false}      | ${true}       | ${true}          | ${true}
        ${'when user cannot report abuse'}        | ${'Report abuse to administrator'} | ${false}                   | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user can submit as spam'}         | ${'Submit as spam'}                | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user cannot submit as spam'}      | ${'Submit as spam'}                | ${false}                   | ${true}        | ${true}        | ${true}       | ${false}      | ${true}          | ${true}
        ${`when user can delete ${issueType}`}    | ${`Delete ${issueType}`}           | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot delete ${issueType}`} | ${`Delete ${issueType}`}           | ${false}                   | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${false}
      `(
        '$description',
        ({
          itemText,
          isItemVisible,
          canUpdateIssue,
          canCreateIssue,
          isIssueAuthor,
          canReportSpam,
          canPromoteToEpic,
          canDestroyIssue,
        }) => {
          beforeEach(() => {
            wrapper = mountComponent({
              props: {
                canUpdateIssue,
                canCreateIssue,
                isIssueAuthor,
                issueType,
                canReportSpam,
                canPromoteToEpic,
                canDestroyIssue,
              },
            });
          });

          it(`${isItemVisible ? 'shows' : 'hides'} "${itemText}" item`, () => {
            expect(
              findDropdownItems()
                .filter((item) => item.text() === itemText)
                .exists(),
            ).toBe(isItemVisible);
          });
        },
      );

      describe(`when user can update but not create ${issueType}`, () => {
        beforeEach(() => {
          wrapper = mountComponent({
            props: {
              canUpdateIssue: true,
              canCreateIssue: false,
              isIssueAuthor: true,
              issueType,
              canReportSpam: false,
              canPromoteToEpic: false,
            },
          });
        });
        it(`${isCloseIssueItemVisible ? 'shows' : 'hides'} the dropdown button`, () => {
          expect(findDropdown().exists()).toBe(isCloseIssueItemVisible);
        });
      });
    });

    describe(`show edit button ${issueType}`, () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            canUpdateIssue: true,
            canCreateIssue: false,
            isIssueAuthor: true,
            issueType,
            canReportSpam: false,
            canPromoteToEpic: false,
          },
        });
      });
      it(`shows the edit button`, () => {
        expect(findEditButton().exists()).toBe(true);
      });

      it('should trigger "open.form" event when clicked', async () => {
        expect(issuesEventHub.$emit).not.toHaveBeenCalled();
        await findEditButton().trigger('click');
        expect(issuesEventHub.$emit).toHaveBeenCalledWith('open.form');
      });
    });
  });

  describe('delete issue button', () => {
    let trackingSpy;

    beforeEach(() => {
      wrapper = mountComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('tracks clicking on button', () => {
      findDesktopDropdownItems().at(3).vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_dropdown', {
        label: 'delete_issue',
      });
    });
  });

  describe('when "Promote to epic" button is clicked', () => {
    describe('when response is successful', () => {
      beforeEach(async () => {
        visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

        wrapper = mountComponent({
          promoteToEpicHandler: promoteToEpicMutationSuccessResponseHandler,
        });

        wrapper.find('[data-testid="promote-button"]').vm.$emit('click');

        await waitForPromises();
      });

      it('invokes GraphQL mutation when clicked', () => {
        expect(promoteToEpicMutationSuccessResponseHandler).toHaveBeenCalledWith({
          input: {
            iid: defaultProps.iid,
            projectPath: defaultProps.projectPath,
          },
        });
      });

      it('shows a success message and tells the user they are being redirected', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'The issue was successfully promoted to an epic. Redirecting to epic...',
          variant: VARIANT_SUCCESS,
        });
      });

      it('redirects to newly created epic path', () => {
        expect(visitUrlSpy).toHaveBeenCalledWith(
          promoteToEpicMutationResponse.data.promoteToEpic.epic.webPath,
        );
      });
    });

    describe('when response contains errors', () => {
      beforeEach(async () => {
        visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

        wrapper = mountComponent({
          promoteToEpicHandler: promoteToEpicMutationErrorHandler,
        });

        wrapper.find('[data-testid="promote-button"]').vm.$emit('click');

        await waitForPromises();
      });

      it('shows an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: HeaderActions.i18n.promoteErrorMessage,
        });
      });
    });
  });

  describe('when `toggle.issuable.state` event is emitted', () => {
    it('invokes a method to toggle the issue state', () => {
      wrapper = mountComponent();

      eventHub.$emit('toggle.issuable.state');

      expect(updateIssueMutationResponseHandler).toHaveBeenCalledWith({
        input: {
          iid: defaultProps.iid,
          projectPath: defaultProps.projectPath,
          stateEvent: ISSUE_STATE_EVENT_CLOSE,
        },
      });
    });
  });

  describe('blocked by issues modal', () => {
    const blockedByIssues = [
      { iid: 13, web_url: 'gitlab-org/gitlab-test/-/issues/13' },
      { iid: 79, web_url: 'gitlab-org/gitlab-test/-/issues/79' },
    ];

    beforeEach(() => {
      wrapper = mountComponent({ blockedByIssues });
    });

    it('has title text', () => {
      expect(findModal().attributes('title')).toBe(
        'Are you sure you want to close this blocked issue?',
      );
    });

    it('has body text', () => {
      expect(findModal().text()).toContain(
        'This issue is currently blocked by the following issues:',
      );
    });

    it('calls apollo mutation when primary button is clicked', () => {
      findModal().vm.$emit('primary');

      expect(updateIssueMutationResponseHandler).toHaveBeenCalledWith({
        input: {
          iid: defaultProps.iid.toString(),
          projectPath: defaultProps.projectPath,
          stateEvent: ISSUE_STATE_EVENT_CLOSE,
        },
      });
    });

    describe.each`
      ordinal     | index
      ${'first'}  | ${0}
      ${'second'} | ${1}
    `('$ordinal blocked-by issue link', ({ index }) => {
      it('has link text', () => {
        expect(findModalLinkAt(index).text()).toBe(`#${blockedByIssues[index].iid}`);
      });

      it('has url', () => {
        expect(findModalLinkAt(index).attributes('href')).toBe(blockedByIssues[index].web_url);
      });
    });
  });

  describe('delete issue modal', () => {
    it('renders', () => {
      wrapper = mountComponent();

      expect(wrapper.findComponent(DeleteIssueModal).props()).toEqual({
        issuePath: defaultProps.issuePath,
        issueType: defaultProps.issueType,
        modalId: HeaderActions.deleteModalId,
        title: 'Delete issue',
      });
    });
  });

  describe('abuse category selector', () => {
    beforeEach(() => {
      wrapper = mountComponent({ props: { isIssueAuthor: false } });
    });

    it("doesn't render", () => {
      expect(findAbuseCategorySelector().exists()).toEqual(false);
    });

    it('opens the drawer', async () => {
      findReportAbuseSelectorItem().vm.$emit('click');

      await nextTick();

      expect(findAbuseCategorySelector().props('showDrawer')).toEqual(true);
    });

    it('closes the drawer', async () => {
      await findReportAbuseSelectorItem().vm.$emit('click');
      await findAbuseCategorySelector().vm.$emit('close-drawer');

      expect(findAbuseCategorySelector().exists()).toEqual(false);
    });
  });

  describe('notification toggle', () => {
    describe('visibility', () => {
      describe.each`
        movedMrSidebarEnabled | issueType        | visible
        ${true}               | ${TYPE_ISSUE}    | ${true}
        ${true}               | ${TYPE_INCIDENT} | ${true}
        ${false}              | ${TYPE_ISSUE}    | ${false}
        ${false}              | ${TYPE_INCIDENT} | ${false}
      `(
        `when movedMrSidebarEnabled flag is "$movedMrSidebarEnabled" with issue type "$issueType"`,
        ({ movedMrSidebarEnabled, issueType, visible }) => {
          beforeEach(() => {
            wrapper = mountComponent({
              props: {
                issueType,
              },
              movedMrSidebarEnabled,
            });
          });

          it(`${visible ? 'shows' : 'hides'} Notification toggle`, () => {
            expect(findNotificationWidget().exists()).toBe(visible);
          });
        },
      );
    });
  });

  describe('lock issue option', () => {
    describe('visibility', () => {
      describe.each`
        movedMrSidebarEnabled | issueType        | visible
        ${true}               | ${TYPE_ISSUE}    | ${true}
        ${true}               | ${TYPE_INCIDENT} | ${false}
        ${false}              | ${TYPE_ISSUE}    | ${false}
        ${false}              | ${TYPE_INCIDENT} | ${false}
      `(
        `when movedMrSidebarEnabled flag is "$movedMrSidebarEnabled" with issue type "$issueType"`,
        ({ movedMrSidebarEnabled, issueType, visible }) => {
          beforeEach(() => {
            wrapper = mountComponent({
              props: {
                issueType,
              },
              movedMrSidebarEnabled,
            });
          });

          it(`${visible ? 'shows' : 'hides'} Lock issue option`, () => {
            expect(findLockIssueWidget().exists()).toBe(visible);
          });
        },
      );
    });
  });

  describe('copy reference option', () => {
    describe('visibility', () => {
      describe.each`
        movedMrSidebarEnabled | issueType        | visible
        ${true}               | ${TYPE_ISSUE}    | ${true}
        ${true}               | ${TYPE_INCIDENT} | ${true}
        ${false}              | ${TYPE_ISSUE}    | ${false}
        ${false}              | ${TYPE_INCIDENT} | ${false}
      `(
        'when movedMrSidebarFlagEnabled is "$movedMrSidebarEnabled" with issue type "$issueType"',
        ({ movedMrSidebarEnabled, issueType, visible }) => {
          beforeEach(() => {
            wrapper = mountComponent({
              props: {
                issueType,
              },
              movedMrSidebarEnabled,
            });
          });

          it(`${visible ? 'shows' : 'hides'} Copy reference option`, () => {
            expect(findCopyRefenceDropdownItem().exists()).toBe(visible);
          });
        },
      );
    });

    describe('clicking when visible', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            issueType: TYPE_ISSUE,
          },
          movedMrSidebarEnabled: true,
        });
      });

      it('shows toast message', () => {
        findCopyRefenceDropdownItem().vm.$emit('click');

        expect(toast).toHaveBeenCalledWith('Reference copied');
      });
    });
  });

  describe('copy email option', () => {
    describe('visibility', () => {
      describe.each`
        movedMrSidebarEnabled | issueType        | issuableEmailAddress    | visible
        ${true}               | ${TYPE_ISSUE}    | ${'mock-email-address'} | ${true}
        ${true}               | ${TYPE_ISSUE}    | ${''}                   | ${false}
        ${true}               | ${TYPE_INCIDENT} | ${'mock-email-address'} | ${true}
        ${true}               | ${TYPE_INCIDENT} | ${''}                   | ${false}
        ${false}              | ${TYPE_ISSUE}    | ${'mock-email-address'} | ${false}
        ${false}              | ${TYPE_INCIDENT} | ${'mock-email-address'} | ${false}
      `(
        'when movedMrSidebarEnabled flag is "$movedMrSidebarEnabled" issue type is "$issueType" and issuableEmailAddress="$issuableEmailAddress"',
        ({ movedMrSidebarEnabled, issueType, issuableEmailAddress, visible }) => {
          beforeEach(() => {
            wrapper = mountComponent({
              props: {
                issueType,
                issuableEmailAddress,
              },
              movedMrSidebarEnabled,
            });
          });

          it(`${visible ? 'shows' : 'hides'} Copy email option`, () => {
            expect(findCopyEmailItem().exists()).toBe(visible);
          });
        },
      );
    });

    describe('clicking when visible', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            issueType: TYPE_ISSUE,
            issuableEmailAddress: 'mock-email-address',
          },
          movedMrSidebarEnabled: true,
        });
      });

      it('shows toast message', () => {
        findCopyEmailItem().vm.$emit('click');

        expect(toast).toHaveBeenCalledWith('Email address copied');
      });
    });
  });
});
