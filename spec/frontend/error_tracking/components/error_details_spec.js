import {
  GlButton,
  GlLoadingIcon,
  GlLink,
  GlBadge,
  GlFormInput,
  GlAlert,
  GlSprintf,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getErrorDetailsQuery from '~/error_tracking/queries/details.query.graphql';
import { severityLevel, severityLevelVariant, errorStatus } from '~/error_tracking/constants';
import ErrorDetails from '~/error_tracking/components/error_details.vue';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import ErrorDetailsInfo from '~/error_tracking/components/error_details_info.vue';
import { createAlert, VARIANT_WARNING } from '~/alert';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import TimelineChart from '~/error_tracking/components/timeline_chart.vue';

jest.mock('~/alert');

Vue.use(Vuex);
Vue.use(VueApollo);

const defaultError = {
  id: 'gid://gitlab/Gitlab::ErrorTracking::DetailedError/129381',
  sentryId: 129381,
  title: 'Issue title',
  userCount: 2,
  count: 12,
  status: 'open',
  firstSeen: '2017-05-26T13:32:48Z',
  lastSeen: '2018-05-26T13:32:48Z',
  message: 'Error',
  culprit: 'Error',
  tags: {
    level: 'high',
    logger: 'ruby',
  },
  externalUrl: 'http://sentry.gitlab.net/gitlab',
  externalBaseUrl: 'https://gitlab.com',
  firstReleaseVersion: 1,
  frequency: null,
  lastReleaseVersion: 2,
  gitlabCommit: '12345678',
  gitlabCommitPath: '/commit/12345678',
  gitlabIssuePath: '/issues/1',
  integrated: true,
};

describe('ErrorDetails', () => {
  let store;
  let wrapper;
  let actions;
  let getters;
  let requestHandlers;

  const mockApolloHandlers = ({ detailedError, getErrorDetailsQueryHandler }) => {
    return {
      getErrorDetailsQuery:
        getErrorDetailsQueryHandler ||
        jest.fn().mockResolvedValue({
          data: {
            id: 1,
            project: {
              id: 2,
              sentryErrors: { id: 3, detailedError: { ...defaultError, ...detailedError } },
            },
          },
        }),
    };
  };

  const createMockApolloProvider = (handlers) => {
    requestHandlers = handlers;
    return createMockApollo([[getErrorDetailsQuery, requestHandlers.getErrorDetailsQuery]]);
  };

  const findInput = (name) => {
    return wrapper
      .findAllComponents(GlFormInput)
      .wrappers.find((c) => c.attributes('name') === name);
  };

  const findUpdateIgnoreStatusButton = () =>
    wrapper.find('[data-testid="update-ignore-status-btn"]');
  const findUpdateResolveStatusButton = () =>
    wrapper.find('[data-testid="update-resolve-status-btn"]');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = async ({
    integratedErrorTrackingEnabled = false,
    getErrorDetailsQueryHandler = null,
    detailedError = {},
  } = {}) => {
    wrapper = shallowMount(ErrorDetails, {
      apolloProvider: createMockApolloProvider(
        mockApolloHandlers({ detailedError, getErrorDetailsQueryHandler }),
      ),
      stubs: {
        GlButton,
        GlSprintf,
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
        GlDisclosureDropdownGroup,
      },
      store,
      propsData: {
        issueId: '123',
        projectPath: '/root/gitlab-test',
        listPath: '/error_tracking',
        issueUpdatePath: '/123',
        issueStackTracePath: '/stacktrace',
        projectIssuesPath: '/test-project/issues/',
        csrfToken: 'fakeToken',
        integratedErrorTrackingEnabled,
      },
    });

    await waitForPromises();
  };

  beforeEach(() => {
    actions = {
      setStatus: jest.fn().mockImplementation(() => {}),
      startPollingStacktrace: jest.fn().mockImplementation(() => {}),
      updateIgnoreStatus: jest.fn().mockResolvedValue({}),
      updateResolveStatus: jest.fn().mockResolvedValue({ closed_issue_iid: 1 }),
    };

    getters = {
      sentryUrl: () => 'sentry.io',
      stacktrace: () => [{ context: [1, 2], lineNo: 53, filename: 'index.js' }],
    };

    const state = {
      stacktraceData: { date_received: '2020-01-01' },
      loadingStacktrace: true,
      errorStatus: '',
    };

    store = new Vuex.Store({
      modules: {
        details: {
          namespaced: true,
          actions,
          state,
          getters,
        },
      },
    });
  });

  describe('loading', () => {
    it('should show spinner while loading', () => {
      createComponent();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
      expect(wrapper.findComponent(Stacktrace).exists()).toBe(false);
    });
  });

  describe('sentry response timeout', () => {
    const initTime = 300000;
    const endTime = initTime + 10000;

    it('when before timeout, still shows loading', async () => {
      jest
        .spyOn(Date, 'now')
        .mockReturnValueOnce(initTime)
        .mockReturnValueOnce(endTime - 1);

      await createComponent({ getErrorDetailsQueryHandler: jest.fn().mockRejectedValue({}) });
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('when timeout is hit and no apollo result, stops loading and shows alert', async () => {
      jest
        .spyOn(Date, 'now')
        .mockReturnValueOnce(initTime)
        .mockReturnValueOnce(endTime + 1);
      await createComponent({ getErrorDetailsQueryHandler: jest.fn().mockRejectedValue({}) });
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
      expect(createAlert).toHaveBeenCalledTimes(2);
      expect(createAlert).toHaveBeenLastCalledWith({
        message: 'Could not connect to Sentry. Refresh the page to try again.',
        variant: VARIANT_WARNING,
      });
    });
  });

  describe('Error details', () => {
    describe('unsafe chars for culprit field', () => {
      const findReportedText = () => wrapper.find('[data-testid="reported-text"]');
      const culprit = '<script>console.log("surprise!")</script>';

      beforeEach(async () => {
        store.state.details.loadingStacktrace = false;
        const detailedError = { culprit };
        await createComponent({ detailedError });
      });

      it('should not convert interpolated text to html entities', () => {
        expect(findReportedText().findAll('script').length).toEqual(0);
        expect(findReportedText().findAll('strong').length).toEqual(1);
      });

      it('should render text instead of converting to html entities', () => {
        expect(findReportedText().text()).toContain(culprit);
      });
    });

    describe('Badges', () => {
      it('should show language and error level badges', async () => {
        const detailedError = { tags: { level: 'error', logger: 'ruby' } };
        await createComponent({ detailedError });
        expect(wrapper.findAllComponents(GlBadge).length).toBe(2);
      });

      it('should NOT show the badge if the tag is not present', async () => {
        const detailedError = { tags: { level: 'error', logger: null } };
        await createComponent({ detailedError });
        expect(wrapper.findAllComponents(GlBadge).length).toBe(1);
      });

      it.each(Object.keys(severityLevel))(
        'should set correct severity level variant for %s badge',
        async (level) => {
          const detailedError = { tags: { level: severityLevel[level], logger: null } };
          await createComponent({ detailedError });
          expect(wrapper.findComponent(GlBadge).props('variant')).toEqual(
            severityLevelVariant[severityLevel[level]],
          );
        },
      );

      it('should fallback for ERROR severityLevelVariant when severityLevel is unknown', async () => {
        const detailedError = { tags: { level: 'someNewErrorLevel', logger: null } };
        await createComponent({ detailedError });
        expect(wrapper.findComponent(GlBadge).props('variant')).toEqual(
          severityLevelVariant[severityLevel.ERROR],
        );
      });
    });

    describe('ErrorDetailsInfo', () => {
      it('should show ErrorDetailsInfo', async () => {
        await createComponent();
        store.state.details.loadingStacktrace = false;
        await nextTick();
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.findComponent(ErrorDetailsInfo).exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('timeline chart', () => {
      it('should not show timeline chart if frequency data does not exist', async () => {
        await createComponent();
        expect(wrapper.findComponent(TimelineChart).exists()).toBe(false);
        expect(wrapper.text()).not.toContain('Last 24 hours');
      });

      it('should show timeline chart', async () => {
        const mockFrequency = [
          { count: 0, time: 1 },
          { count: 2, time: 3 },
        ];
        const detailedError = { frequency: mockFrequency };
        await createComponent({ detailedError });
        expect(wrapper.findComponent(TimelineChart).exists()).toBe(true);
        expect(wrapper.findComponent(TimelineChart).props('timelineData')).toEqual(mockFrequency);
        expect(wrapper.text()).toContain('Last 24 hours');
      });
    });

    describe('Stacktrace', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('should show stacktrace', async () => {
        store.state.details.loadingStacktrace = false;
        await nextTick();
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.findComponent(Stacktrace).exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
      });

      it('should NOT show stacktrace if no entries and show Alert message', async () => {
        store.state.details.loadingStacktrace = false;
        store.getters = { 'details/sentryUrl': () => 'sentry.io', 'details/stacktrace': () => [] };
        await nextTick();
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.findComponent(Stacktrace).exists()).toBe(false);
        expect(findAlert().text()).toBe('No stack trace for this error');
      });
    });

    describe('When a user clicks the create issue button', () => {
      beforeEach(async () => {
        await createComponent({ detailedError: { gitlabIssuePath: '' } });
      });

      it('should send sentry_issue_identifier', () => {
        const sentryErrorIdInput = findInput(
          'issue[sentry_issue_attributes][sentry_issue_identifier]',
        );
        expect(sentryErrorIdInput.attributes('value')).toBe('129381');
      });

      it('should set the form values with title and description', () => {
        const csrfTokenInput = findInput('authenticity_token');
        const issueTitleInput = findInput('issue[title]');
        const issueDescriptionInput = wrapper.find('input[name="issue[description]"]');
        expect(csrfTokenInput.attributes('value')).toBe('fakeToken');
        expect(issueTitleInput.attributes('value')).toContain(wrapper.vm.issueTitle);
        expect(issueDescriptionInput.attributes('value')).toContain(wrapper.vm.issueDescription);
      });

      it('should submit the form', () => {
        window.HTMLFormElement.prototype.submit = () => {};
        const submitSpy = jest.spyOn(wrapper.vm.$refs.sentryIssueForm, 'submit');
        wrapper.find('[data-testid="create-issue-button"]').vm.$emit('click');
        expect(submitSpy).toHaveBeenCalled();
        submitSpy.mockRestore();
      });
    });

    describe('Status update', () => {
      afterEach(() => {
        actions.updateIgnoreStatus.mockClear();
        actions.updateResolveStatus.mockClear();
      });

      describe('when error is unresolved', () => {
        beforeEach(async () => {
          await createComponent();
          store.state.details.errorStatus = errorStatus.UNRESOLVED;
          await nextTick();
        });

        it('displays Ignore and Resolve buttons', () => {
          expect(findUpdateIgnoreStatusButton().text()).toBe('Ignore');
          expect(findUpdateResolveStatusButton().text()).toBe('Resolve');
        });

        it('marks error as ignored when ignore button is clicked', () => {
          findUpdateIgnoreStatusButton().vm.$emit('click');
          expect(actions.updateIgnoreStatus.mock.calls[0][1]).toEqual(
            expect.objectContaining({ status: errorStatus.IGNORED }),
          );
        });

        it('marks error as resolved when resolve button is clicked', () => {
          findUpdateResolveStatusButton().vm.$emit('click');
          expect(actions.updateResolveStatus.mock.calls[0][1]).toEqual(
            expect.objectContaining({ status: errorStatus.RESOLVED }),
          );
        });
      });

      describe('when error is ignored', () => {
        beforeEach(async () => {
          await createComponent();
          store.state.details.errorStatus = errorStatus.IGNORED;
          await nextTick();
        });

        it('displays Undo Ignore and Resolve buttons', () => {
          expect(findUpdateIgnoreStatusButton().text()).toBe('Undo ignore');
          expect(findUpdateResolveStatusButton().text()).toBe('Resolve');
        });

        it('marks error as unresolved when ignore button is clicked', () => {
          findUpdateIgnoreStatusButton().vm.$emit('click');
          expect(actions.updateIgnoreStatus.mock.calls[0][1]).toEqual(
            expect.objectContaining({ status: errorStatus.UNRESOLVED }),
          );
        });

        it('marks error as resolved when resolve button is clicked', () => {
          findUpdateResolveStatusButton().vm.$emit('click');
          expect(actions.updateResolveStatus.mock.calls[0][1]).toEqual(
            expect.objectContaining({ status: errorStatus.RESOLVED }),
          );
        });
      });

      describe('when error is resolved', () => {
        beforeEach(async () => {
          await createComponent();
          store.state.details.errorStatus = errorStatus.RESOLVED;
          await nextTick();
        });

        it('displays Ignore and Unresolve buttons', () => {
          expect(findUpdateIgnoreStatusButton().text()).toBe('Ignore');
          expect(findUpdateResolveStatusButton().text()).toBe('Unresolve');
        });

        it('marks error as ignored when ignore button is clicked', () => {
          findUpdateIgnoreStatusButton().vm.$emit('click');
          expect(actions.updateIgnoreStatus.mock.calls[0][1]).toEqual(
            expect.objectContaining({ status: errorStatus.IGNORED }),
          );
        });

        it('marks error as unresolved when unresolve button is clicked', () => {
          findUpdateResolveStatusButton().vm.$emit('click');
          expect(actions.updateResolveStatus.mock.calls[0][1]).toEqual(
            expect.objectContaining({ status: errorStatus.UNRESOLVED }),
          );
        });

        it('should show alert with closed issueId', async () => {
          await findUpdateResolveStatusButton().vm.$emit('click');
          await waitForPromises();
          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toBe(
            'The associated issue #1 has been closed as the error is now resolved.',
          );
        });
      });
    });

    describe('GitLab issue link', () => {
      const gitlabIssuePath = 'https://gitlab.example.com/issues/1';
      const findGitLabLink = () => wrapper.find(`[href="${gitlabIssuePath}"]`);
      const findCreateIssueButton = () => wrapper.find('[data-testid="create-issue-button"]');
      const findViewIssueButton = () => wrapper.find('[data-testid="view-issue-button"]');

      describe('is present', () => {
        beforeEach(async () => {
          const detailedError = { gitlabIssuePath };
          await createComponent({ detailedError });
        });

        it('should display the View issue button', () => {
          expect(findViewIssueButton().exists()).toBe(true);
        });

        it('should display the issue link', () => {
          expect(findGitLabLink().exists()).toBe(true);
        });

        it('should not display a create issue button', () => {
          expect(findCreateIssueButton().exists()).toBe(false);
        });
      });

      describe('is not present', () => {
        beforeEach(async () => {
          const detailedError = { gitlabIssuePath: null };
          await createComponent({ detailedError });
        });

        it('should not display the View issue button', () => {
          expect(findViewIssueButton().exists()).toBe(false);
        });

        it('should not display an issue link', () => {
          expect(findGitLabLink().exists()).toBe(false);
        });

        it('should display the create issue button', () => {
          expect(findCreateIssueButton().exists()).toBe(true);
        });
      });
    });
  });

  describe('Snowplow tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    describe.each`
      integrated | variant
      ${true}    | ${'integrated'}
      ${false}   | ${'external'}
    `(`when integratedErrorTracking is $integrated`, ({ integrated, variant }) => {
      const category = 'Error Tracking';

      beforeEach(async () => {
        await createComponent({
          integratedErrorTrackingEnabled: integrated,
          detailedError: { gitlabIssuePath: '' },
        });
      });

      it('should track detail page views', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        expect(trackEventSpy).toHaveBeenCalledWith(
          'view_error_details',
          {
            variant,
          },
          category,
        );
      });

      it('should track IGNORE status update', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        await findUpdateIgnoreStatusButton().trigger('click');

        expect(trackEventSpy).toHaveBeenCalledWith(
          'update_ignored_status',
          {
            variant,
          },
          category,
        );
      });

      it('should track RESOLVE status update', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await findUpdateResolveStatusButton().trigger('click');
        expect(trackEventSpy).toHaveBeenCalledWith(
          'update_resolved_status',
          {
            variant,
          },
          category,
        );
      });

      it('should track create issue button click', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await wrapper.find('[data-testid="create-issue-button"]').vm.$emit('click');
        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_create_issue_from_error',
          {
            variant,
          },
          category,
        );
      });
    });
  });
});
