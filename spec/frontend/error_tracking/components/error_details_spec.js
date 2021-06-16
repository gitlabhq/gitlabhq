import {
  GlButton,
  GlLoadingIcon,
  GlLink,
  GlBadge,
  GlFormInput,
  GlAlert,
  GlSprintf,
} from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  severityLevel,
  severityLevelVariant,
  errorStatus,
} from '~/error_tracking/components/constants';
import ErrorDetails from '~/error_tracking/components/error_details.vue';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import {
  trackClickErrorLinkToSentryOptions,
  trackErrorDetailsViewsOptions,
  trackErrorStatusUpdateOptions,
} from '~/error_tracking/utils';
import createFlash from '~/flash';
import { __ } from '~/locale';
import Tracking from '~/tracking';

jest.mock('~/flash');

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorDetails', () => {
  let store;
  let wrapper;
  let actions;
  let getters;
  let mocks;
  const externalUrl = 'https://sentry.io/organizations/test-sentry-nk/issues/1/?project=1';

  const findInput = (name) => {
    const inputs = wrapper.findAll(GlFormInput).filter((c) => c.attributes('name') === name);
    return inputs.length ? inputs.at(0) : inputs;
  };

  const findUpdateIgnoreStatusButton = () =>
    wrapper.find('[data-testid="update-ignore-status-btn"]');
  const findUpdateResolveStatusButton = () =>
    wrapper.find('[data-testid="update-resolve-status-btn"]');
  const findExternalUrl = () => wrapper.find('[data-testid="external-url-link"]');
  const findAlert = () => wrapper.find(GlAlert);

  function mountComponent() {
    wrapper = shallowMount(ErrorDetails, {
      stubs: { GlButton, GlSprintf },
      localVue,
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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('should show spinner while loading', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(GlLink).exists()).toBe(false);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
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

    it('when before timeout, still shows loading', () => {
      Date.now.mockReturnValue(endTime - 1);

      wrapper.vm.onNoApolloResult();

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
        expect(createFlash).not.toHaveBeenCalled();
        expect(mocks.$apollo.queries.error.stopPolling).not.toHaveBeenCalled();
      });
    });

    it('when timeout is hit and no apollo result, stops loading and shows flash', () => {
      Date.now.mockReturnValue(endTime + 1);

      wrapper.vm.onNoApolloResult();

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.find(GlLink).exists()).toBe(false);
        expect(createFlash).toHaveBeenCalledWith({
          message: 'Could not connect to Sentry. Refresh the page to try again.',
          type: 'warning',
        });
        expect(mocks.$apollo.queries.error.stopPolling).toHaveBeenCalled();
      });
    });
  });

  describe('Error details', () => {
    beforeEach(() => {
      mocks.$apollo.queries.error.loading = false;
      mountComponent();
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

    it('should show Sentry error details without stacktrace', () => {
      expect(wrapper.find(GlLink).exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
      expect(wrapper.find(GlBadge).exists()).toBe(false);
      expect(wrapper.findAll(GlButton)).toHaveLength(3);
    });

    describe('unsafe chars for culprit field', () => {
      const findReportedText = () => wrapper.find('[data-qa-selector="reported_text"]');
      const culprit = '<script>console.log("surprise!")</script>';
      beforeEach(() => {
        store.state.details.loadingStacktrace = false;
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
      it('should show language and error level badges', () => {
        wrapper.setData({
          error: {
            tags: { level: 'error', logger: 'ruby' },
          },
        });
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlBadge).length).toBe(2);
        });
      });

      it('should NOT show the badge if the tag is not present', () => {
        wrapper.setData({
          error: {
            tags: { level: 'error' },
          },
        });
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlBadge).length).toBe(1);
        });
      });

      it.each(Object.keys(severityLevel))(
        'should set correct severity level variant for %s badge',
        (level) => {
          wrapper.setData({
            error: {
              tags: { level: severityLevel[level] },
            },
          });
          return wrapper.vm.$nextTick().then(() => {
            expect(wrapper.find(GlBadge).props('variant')).toEqual(
              severityLevelVariant[severityLevel[level]],
            );
          });
        },
      );

      it('should fallback for ERROR severityLevelVariant when severityLevel is unknown', () => {
        wrapper.setData({
          error: {
            tags: { level: 'someNewErrorLevel' },
          },
        });
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(GlBadge).props('variant')).toEqual(
            severityLevelVariant[severityLevel.ERROR],
          );
        });
      });
    });

    describe('Stacktrace', () => {
      it('should show stacktrace', () => {
        store.state.details.loadingStacktrace = false;
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.find(Stacktrace).exists()).toBe(true);
          expect(findAlert().exists()).toBe(false);
        });
      });

      it('should NOT show stacktrace if no entries and show Alert message', () => {
        store.state.details.loadingStacktrace = false;
        store.getters = { 'details/sentryUrl': () => 'sentry.io', 'details/stacktrace': () => [] };
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.find(Stacktrace).exists()).toBe(false);
          expect(findAlert().text()).toBe('No stack trace for this error');
        });
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
        beforeEach(() => {
          store.state.details.errorStatus = errorStatus.UNRESOLVED;

          return wrapper.vm.$nextTick();
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
        beforeEach(() => {
          store.state.details.errorStatus = errorStatus.IGNORED;

          return wrapper.vm.$nextTick();
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
        beforeEach(() => {
          store.state.details.errorStatus = errorStatus.RESOLVED;

          return wrapper.vm.$nextTick();
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

        it('should show alert with closed issueId', () => {
          const closedIssueId = 123;
          wrapper.setData({
            isAlertVisible: true,
            closedIssueId,
          });

          return wrapper.vm.$nextTick().then(() => {
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toContain(`#${closedIssueId}`);
          });
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

    describe('GitLab commit link', () => {
      const gitlabCommit = '7975be0116940bf2ad4321f79d02a55c5f7779aa';
      const gitlabCommitPath =
        '/gitlab-org/gitlab-test/commit/7975be0116940bf2ad4321f79d02a55c5f7779aa';
      const findGitLabCommitLink = () => wrapper.find(`[href$="${gitlabCommitPath}"]`);

      it('should display a link', () => {
        mocks.$apollo.queries.error.loading = false;
        wrapper.setData({
          error: {
            gitlabCommit,
            gitlabCommitPath,
          },
        });
        return wrapper.vm.$nextTick().then(() => {
          expect(findGitLabCommitLink().exists()).toBe(true);
        });
      });

      it('should not display a link', () => {
        mocks.$apollo.queries.error.loading = false;
        wrapper.setData({
          error: {
            gitlabCommit: null,
          },
        });
        return wrapper.vm.$nextTick().then(() => {
          expect(findGitLabCommitLink().exists()).toBe(false);
        });
      });
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mocks.$apollo.queries.error.loading = false;
      mountComponent();
      wrapper.setData({
        error: { externalUrl },
      });
    });

    it('should track detail page views', () => {
      const { category, action } = trackErrorDetailsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track IGNORE status update', () => {
      Tracking.event.mockClear();
      findUpdateIgnoreStatusButton().vm.$emit('click');
      setImmediate(() => {
        const { category, action } = trackErrorStatusUpdateOptions('ignored');
        expect(Tracking.event).toHaveBeenCalledWith(category, action);
      });
    });

    it('should track RESOLVE status update', () => {
      Tracking.event.mockClear();
      findUpdateResolveStatusButton().vm.$emit('click');
      setImmediate(() => {
        const { category, action } = trackErrorStatusUpdateOptions('resolved');
        expect(Tracking.event).toHaveBeenCalledWith(category, action);
      });
    });

    it('should track external Sentry link views', () => {
      Tracking.event.mockClear();
      findExternalUrl().trigger('click');
      setImmediate(() => {
        const { category, action, label, property } = trackClickErrorLinkToSentryOptions(
          externalUrl,
        );
        expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property });
      });
    });
  });
});
