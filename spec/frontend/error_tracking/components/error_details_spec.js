import {
  GlButton,
  GlLoadingIcon,
  GlLink,
  GlBadge,
  GlFormInput,
  GlAlert,
  GlSprintf,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { severityLevel, severityLevelVariant, errorStatus } from '~/error_tracking/constants';
import ErrorDetails from '~/error_tracking/components/error_details.vue';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import ErrorDetailsInfo from '~/error_tracking/components/error_details_info.vue';
import {
  trackErrorDetailsViewsOptions,
  trackErrorStatusUpdateOptions,
  trackCreateIssueFromError,
} from '~/error_tracking/events_tracking';
import { createAlert, VARIANT_WARNING } from '~/alert';
import { __ } from '~/locale';
import Tracking from '~/tracking';

jest.mock('~/alert');

Vue.use(Vuex);

describe('ErrorDetails', () => {
  let store;
  let wrapper;
  let actions;
  let getters;
  let mocks;
  const externalUrl = 'https://sentry.io/organizations/test-sentry-nk/issues/1/?project=1';

  const findInput = (name) => {
    const inputs = wrapper
      .findAllComponents(GlFormInput)
      .filter((c) => c.attributes('name') === name);
    return inputs.length ? inputs.at(0) : inputs;
  };

  const findUpdateIgnoreStatusButton = () =>
    wrapper.find('[data-testid="update-ignore-status-btn"]');
  const findUpdateResolveStatusButton = () =>
    wrapper.find('[data-testid="update-resolve-status-btn"]');
  const findAlert = () => wrapper.findComponent(GlAlert);

  function mountComponent() {
    wrapper = shallowMount(ErrorDetails, {
      stubs: { GlButton, GlSprintf },
      store,
      mocks,
      propsData: {
        issueId: '123',
        projectPath: '/root/gitlab-test',
        listPath: '/error_tracking',
        issueUpdatePath: '/123',
        issueStackTracePath: '/stacktrace',
        projectIssuesPath: '/test-project/issues/',
        csrfToken: 'fakeToken',
      },
    });
  }

  beforeEach(() => {
    actions = {
      startPollingStacktrace: () => {},
      updateIgnoreStatus: jest.fn().mockResolvedValue({}),
      updateResolveStatus: jest.fn().mockResolvedValue({ closed_issue_iid: 1 }),
    };

    getters = {
      sentryUrl: () => 'sentry.io',
      stacktrace: () => [{ context: [1, 2], lineNo: 53, filename: 'index.js' }],
    };

    const state = {
      stacktraceData: {},
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

    const query = jest.fn();
    mocks = {
      $apollo: {
        query,
        queries: {
          error: {
            loading: true,
            stopPolling: jest.fn(),
            setOptions: jest.fn(),
          },
        },
      },
    };
  });

  describe('loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('should show spinner while loading', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
      expect(wrapper.findComponent(Stacktrace).exists()).toBe(false);
    });
  });

  describe('sentry response timeout', () => {
    const initTime = 300000;
    const endTime = initTime + 10000;

    beforeEach(() => {
      mocks.$apollo.queries.error.loading = false;
      jest.spyOn(Date, 'now').mockReturnValue(initTime);
      mountComponent();
    });

    it('when before timeout, still shows loading', async () => {
      Date.now.mockReturnValue(endTime - 1);

      wrapper.vm.onNoApolloResult();

      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(createAlert).not.toHaveBeenCalled();
      expect(mocks.$apollo.queries.error.stopPolling).not.toHaveBeenCalled();
    });

    it('when timeout is hit and no apollo result, stops loading and shows alert', async () => {
      Date.now.mockReturnValue(endTime + 1);

      wrapper.vm.onNoApolloResult();

      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Could not connect to Sentry. Refresh the page to try again.',
        variant: VARIANT_WARNING,
      });
      expect(mocks.$apollo.queries.error.stopPolling).toHaveBeenCalled();
    });
  });

  describe('Error details', () => {
    beforeEach(() => {
      mocks.$apollo.queries.error.loading = false;
      mountComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        error: {
          id: 'gid://gitlab/Gitlab::ErrorTracking::DetailedError/129381',
          sentryId: 129381,
          title: 'Issue title',
          externalUrl: 'http://sentry.gitlab.net/gitlab',
          firstSeen: '2017-05-26T13:32:48Z',
          lastSeen: '2018-05-26T13:32:48Z',
          count: 12,
          userCount: 2,
        },
        stacktraceData: {
          date_received: '2020-05-20',
        },
      });
    });

    describe('unsafe chars for culprit field', () => {
      const findReportedText = () => wrapper.find('[data-qa-selector="reported_text"]');
      const culprit = '<script>console.log("surprise!")</script>';
      beforeEach(() => {
        store.state.details.loadingStacktrace = false;
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          error: {
            culprit,
          },
        });
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
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          error: {
            tags: { level: 'error', logger: 'ruby' },
          },
        });
        await nextTick();
        expect(wrapper.findAllComponents(GlBadge).length).toBe(2);
      });

      it('should NOT show the badge if the tag is not present', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          error: {
            tags: { level: 'error' },
          },
        });
        await nextTick();
        expect(wrapper.findAllComponents(GlBadge).length).toBe(1);
      });

      it.each(Object.keys(severityLevel))(
        'should set correct severity level variant for %s badge',
        async (level) => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            error: {
              tags: { level: severityLevel[level] },
            },
          });
          await nextTick();
          expect(wrapper.findComponent(GlBadge).props('variant')).toEqual(
            severityLevelVariant[severityLevel[level]],
          );
        },
      );

      it('should fallback for ERROR severityLevelVariant when severityLevel is unknown', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          error: {
            tags: { level: 'someNewErrorLevel' },
          },
        });
        await nextTick();
        expect(wrapper.findComponent(GlBadge).props('variant')).toEqual(
          severityLevelVariant[severityLevel.ERROR],
        );
      });
    });

    describe('ErrorDetailsInfo', () => {
      it('should show ErrorDetailsInfo', async () => {
        store.state.details.loadingStacktrace = false;
        await nextTick();
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.findComponent(ErrorDetailsInfo).exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('Stacktrace', () => {
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
        wrapper.find('[data-qa-selector="create_issue_button"]').vm.$emit('click');
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
          store.state.details.errorStatus = errorStatus.UNRESOLVED;

          await nextTick();
        });

        it('displays Ignore and Resolve buttons', () => {
          expect(findUpdateIgnoreStatusButton().text()).toBe(__('Ignore'));
          expect(findUpdateResolveStatusButton().text()).toBe(__('Resolve'));
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
          store.state.details.errorStatus = errorStatus.IGNORED;

          await nextTick();
        });

        it('displays Undo Ignore and Resolve buttons', () => {
          expect(findUpdateIgnoreStatusButton().text()).toBe(__('Undo ignore'));
          expect(findUpdateResolveStatusButton().text()).toBe(__('Resolve'));
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
          store.state.details.errorStatus = errorStatus.RESOLVED;

          await nextTick();
        });

        it('displays Ignore and Unresolve buttons', () => {
          expect(findUpdateIgnoreStatusButton().text()).toBe(__('Ignore'));
          expect(findUpdateResolveStatusButton().text()).toBe(__('Unresolve'));
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
          const closedIssueId = 123;
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            isAlertVisible: true,
            closedIssueId,
          });

          await nextTick();
          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toContain(`#${closedIssueId}`);
        });
      });
    });

    describe('GitLab issue link', () => {
      const gitlabIssuePath = 'https://gitlab.example.com/issues/1';
      const findGitLabLink = () => wrapper.find(`[href="${gitlabIssuePath}"]`);
      const findCreateIssueButton = () => wrapper.find('[data-qa-selector="create_issue_button"]');
      const findViewIssueButton = () => wrapper.find('[data-qa-selector="view_issue_button"]');

      describe('is present', () => {
        beforeEach(() => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            error: {
              gitlabIssuePath,
            },
          });
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
        beforeEach(() => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            error: {
              gitlabIssuePath: null,
            },
          });
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
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mocks.$apollo.queries.error.loading = false;
      mountComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        error: { externalUrl },
      });
    });

    it('should track detail page views', () => {
      const { category, action } = trackErrorDetailsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track IGNORE status update', async () => {
      await findUpdateIgnoreStatusButton().trigger('click');
      const { category, action } = trackErrorStatusUpdateOptions('ignored');
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track RESOLVE status update', async () => {
      await findUpdateResolveStatusButton().trigger('click');
      const { category, action } = trackErrorStatusUpdateOptions('resolved');
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track create issue button click', async () => {
      await wrapper.find('[data-qa-selector="create_issue_button"]').vm.$emit('click');
      const { category, action } = trackCreateIssueFromError;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});
