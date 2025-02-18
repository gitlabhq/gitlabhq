import Vue, { nextTick } from 'vue';
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlLink,
  GlModal,
  GlButton,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import {
  STATUS_CLOSED,
  STATUS_OPEN,
  TYPE_INCIDENT,
  TYPE_ISSUE,
  TYPE_TEST_CASE,
  TYPE_ALERT,
  TYPE_MERGE_REQUEST,
} from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import HeaderActions from '~/issues/show/components/header_actions.vue';
import { ISSUE_STATE_EVENT_CLOSE, ISSUE_STATE_EVENT_REOPEN } from '~/issues/show/constants';
import issuesEventHub from '~/issues/show/event_hub';
import promoteToEpicMutation from '~/issues/show/queries/promote_to_epic.mutation.graphql';
import * as urlUtility from '~/lib/utils/url_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import eventHub from '~/notes/event_hub';
import createStore from '~/notes/stores';
import createMockApollo from 'helpers/mock_apollo_helper';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import updateIssueMutation from '~/issues/show/queries/update_issue.mutation.graphql';
import toast from '~/vue_shared/plugins/global_toast';
import HeaderActionsConfidentialityToggle from '~/issues/show/components/header_actions_confidentiality_toggle.vue';

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

  const findToggleIssueStateButton = () =>
    wrapper.find(`[data-testid="toggle-issue-state-button"]`);
  const findEditButton = () => wrapper.find(`[data-testid="edit-button"]`);

  const findDropdownBy = (dataTestId) => wrapper.find(`[data-testid="${dataTestId}"]`);
  const findMobileDropdown = () => findDropdownBy('mobile-dropdown');
  const findDesktopDropdown = () => findDropdownBy('desktop-dropdown');
  const findMobileDropdownItems = () =>
    findMobileDropdown().findAllComponents(GlDisclosureDropdownItem);
  const findDesktopDropdownItems = () =>
    findDesktopDropdown().findAllComponents(GlDisclosureDropdownItem);
  const findDesktopDropdownTooltip = () => getBinding(findDesktopDropdown().element, 'gl-tooltip');
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findReportAbuseButton = () => wrapper.findByTestId('report-abuse-item');
  const findCopyRefenceDropdownItem = () => wrapper.findByTestId('copy-reference');
  const findCopyEmailItem = () => wrapper.findByTestId('copy-email');
  const findPromoteToEpicButton = () => wrapper.findByTestId('promote-button');
  const findLockIssueToggle = () => wrapper.findByTestId('lock-issue-toggle');

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
    isLoggedIn = true,
    props = {},
    issueState = STATUS_OPEN,
    blockedByIssues = [],
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

    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    return shallowMountExtended(HeaderActions, {
      apolloProvider: createMockApollo(handlers),
      store,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlButton,
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: {
            close: jest.fn(),
          },
        }),
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
          findToggleIssueStateButton().vm.$emit('action');

          expect(updateIssueMutationResponseHandler).toHaveBeenCalledWith({
            input: {
              iid: defaultProps.iid,
              projectPath: defaultProps.projectPath,
              stateEvent: newIssueState,
            },
          });
        });

        it('dispatches a custom event to update the issue page', async () => {
          findToggleIssueStateButton().vm.$emit('action');

          await waitForPromises();

          expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe.each`
      description           | findDropdownItems
      ${'mobile dropdown'}  | ${findMobileDropdownItems}
      ${'desktop dropdown'} | ${findDesktopDropdownItems}
    `('$description', ({ findDropdownItems }) => {
      describe.each`
        description                               | itemText                      | isItemVisible | canUpdateIssue | canCreateIssue | isIssueAuthor | canReportSpam | canPromoteToEpic | canDestroyIssue
        ${`when user can update ${issueType}`}    | ${`Close ${issueType}`}       | ${true}       | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot update ${issueType}`} | ${`Close ${issueType}`}       | ${false}      | ${false}       | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user can create ${issueType}`}    | ${`New related ${issueType}`} | ${true}       | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot create ${issueType}`} | ${`New related ${issueType}`} | ${false}      | ${true}        | ${false}       | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user can promote to epic'}        | ${'Promote to epic'}          | ${true}       | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user cannot promote to epic'}     | ${'Promote to epic'}          | ${false}      | ${true}        | ${true}        | ${true}       | ${true}       | ${false}         | ${true}
        ${'when user can report abuse'}           | ${'Report abuse'}             | ${true}       | ${true}        | ${true}        | ${false}      | ${true}       | ${true}          | ${true}
        ${'when user cannot report abuse'}        | ${'Report abuse'}             | ${false}      | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user can submit as spam'}         | ${'Submit as spam'}           | ${true}       | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user cannot submit as spam'}      | ${'Submit as spam'}           | ${false}      | ${true}        | ${true}        | ${true}       | ${false}      | ${true}          | ${true}
        ${`when user can delete ${issueType}`}    | ${`Delete ${issueType}`}      | ${true}       | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot delete ${issueType}`} | ${`Delete ${issueType}`}      | ${false}      | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${false}
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
                .filter((item) => {
                  return item.props('item')
                    ? item.props('item').text === itemText
                    : item.text() === itemText;
                })
                .exists(),
            ).toBe(isItemVisible);
          });
        },
      );
    });

    it('renders tooltip on desktop dropdown', () => {
      wrapper = mountComponent();

      expect(findDesktopDropdownTooltip().value).toBe('Issue actions');
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
        await findEditButton().vm.$emit('click');
        expect(issuesEventHub.$emit).toHaveBeenCalledWith('open.form');
      });
    });
  });

  describe('Locking discussion', () => {
    it.each`
      description                                                                                    | canUpdateIssue | issueType        | isLoggedIn | isExpected
      ${'shows lock issue toggle when type is issue, user is signed in, and canUpdateIssue is true'} | ${true}        | ${TYPE_ISSUE}    | ${true}    | ${true}
      ${'does not show lock issue toggle if canUpdateIssue is false'}                                | ${false}       | ${TYPE_ISSUE}    | ${true}    | ${false}
      ${'does not show lock issue toggle if type is not issue'}                                      | ${true}        | ${TYPE_INCIDENT} | ${true}    | ${false}
      ${'does not show lock issue toggle if user is not signed in'}                                  | ${true}        | ${TYPE_ISSUE}    | ${false}   | ${false}
    `('$description', ({ canUpdateIssue, issueType, isLoggedIn, isExpected }) => {
      wrapper = mountComponent({
        isLoggedIn,
        props: {
          canUpdateIssue,
          issueType,
        },
      });

      expect(findLockIssueToggle().exists()).toBe(isExpected);
    });
  });

  describe('delete issue button', () => {
    let trackingSpy;

    beforeEach(() => {
      wrapper = mountComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('tracks clicking on button', () => {
      findDesktopDropdownItems().at(5).vm.$emit('action');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_dropdown', {
        label: 'delete_issue',
      });
    });
  });

  describe('"Promote to epic" button behavior', () => {
    describe('default', () => {
      it('the button is enabled when the user can promote to epic', () => {
        wrapper = mountComponent();

        expect(findPromoteToEpicButton().props('item')).toMatchObject({
          extraAttrs: { disabled: false },
          text: 'Promote to epic',
        });
      });
    });

    describe('when request is in flight', () => {
      it('disables the promote option', async () => {
        wrapper = mountComponent({
          promoteToEpicHandler: promoteToEpicMutationSuccessResponseHandler,
        });

        findPromoteToEpicButton().vm.$emit('action');

        await nextTick();

        expect(findPromoteToEpicButton().props('item')).toMatchObject({
          extraAttrs: { disabled: true },
          text: 'Promote to epic',
        });
      });
    });

    describe('when response is successful', () => {
      beforeEach(async () => {
        visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

        wrapper = mountComponent({
          promoteToEpicHandler: promoteToEpicMutationSuccessResponseHandler,
        });

        wrapper.find('[data-testid="promote-button"]').vm.$emit('action');

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

        wrapper.find('[data-testid="promote-button"]').vm.$emit('action');

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

  describe('report abuse to admin button', () => {
    beforeEach(() => {
      wrapper = mountComponent({ props: { isIssueAuthor: false } });
    });

    it('renders the button but not the abuse category drawer', () => {
      expect(findReportAbuseButton().exists()).toBe(true);
      expect(findAbuseCategorySelector().exists()).toEqual(false);
    });

    it('opens the abuse category drawer', async () => {
      findReportAbuseButton().vm.$emit('action');

      await nextTick();

      expect(findAbuseCategorySelector().props('showDrawer')).toEqual(true);
    });

    it('closes the abuse category drawer', async () => {
      await findReportAbuseButton().vm.$emit('action');
      expect(findAbuseCategorySelector().exists()).toEqual(true);

      await findAbuseCategorySelector().vm.$emit('close-drawer');
      expect(findAbuseCategorySelector().exists()).toEqual(false);
    });

    describe('when the logged in user is the issue author', () => {
      beforeEach(() => {
        wrapper = mountComponent({ props: { isIssueAuthor: true } });
      });

      it('does not render the button', () => {
        expect(findReportAbuseButton().exists()).toBe(false);
      });
    });
  });

  describe('copy reference option', () => {
    describe('clicking when visible', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            issueType: TYPE_ISSUE,
          },
        });
      });

      it('shows toast message', () => {
        findCopyRefenceDropdownItem().vm.$emit('action');

        expect(toast).toHaveBeenCalledWith('Reference copied');
      });

      it('contains copy reference class', () => {
        expect(findCopyRefenceDropdownItem().classes()).toContain('js-copy-reference');
      });
    });
  });

  describe('copy email option', () => {
    describe('clicking when visible', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            issueType: TYPE_ISSUE,
            issuableEmailAddress: 'mock-email-address',
          },
        });
      });

      it('shows toast message', () => {
        findCopyEmailItem().vm.$emit('action');

        expect(toast).toHaveBeenCalledWith('Email address copied');
      });
    });
  });

  describe('toggle confidentiality option', () => {
    it.each`
      issueType            | canUpdateIssue | isVisible | showHide
      ${TYPE_ISSUE}        | ${true}        | ${true}   | ${'shows'}
      ${TYPE_INCIDENT}     | ${true}        | ${true}   | ${'shows'}
      ${TYPE_ISSUE}        | ${false}       | ${false}  | ${'hides'}
      ${TYPE_INCIDENT}     | ${false}       | ${false}  | ${'hides'}
      ${'some_other_type'} | ${true}        | ${false}  | ${'hides'}
    `(
      '$showHide toggle confidentiality option for issueType $issueType and canUpdateIssue $canUpdateIssue',
      ({ issueType, canUpdateIssue, isVisible }) => {
        wrapper = mountComponent({
          props: {
            issueType,
            canUpdateIssue,
          },
        });

        expect(wrapper.findComponent(HeaderActionsConfidentialityToggle).exists()).toBe(isVisible);
      },
    );
  });

  describe('issue type text', () => {
    it.each`
      issueType             | expectedText
      ${TYPE_ISSUE}         | ${'issue'}
      ${TYPE_INCIDENT}      | ${'incident'}
      ${TYPE_MERGE_REQUEST} | ${'merge request'}
      ${TYPE_ALERT}         | ${'alert'}
      ${TYPE_TEST_CASE}     | ${'test case'}
      ${'unknown'}          | ${'unknown'}
    `('$issueType', ({ issueType, expectedText }) => {
      wrapper = mountComponent({
        props: { issueType, issuableEmailAddress: 'mock-email-address' },
      });

      expect(wrapper.findComponent(GlDisclosureDropdown).props('toggleText')).toBe(
        `${capitalizeFirstCharacter(expectedText)} actions`,
      );
      expect(findDropdownBy('copy-email').text()).toBe(`Copy ${expectedText} email address`);
      expect(findDesktopDropdownItems().at(1).props('item').text).toBe(
        `New related ${expectedText}`,
      );
    });
  });
});
