import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlLink, GlBadge, GlFormInput } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import ErrorDetails from '~/error_tracking/components/error_details.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorDetails', () => {
  let store;
  let wrapper;
  let actions;
  let getters;
  let mocks;

  const findInput = name => {
    const inputs = wrapper.findAll(GlFormInput).filter(c => c.attributes('name') === name);
    return inputs.length ? inputs.at(0) : inputs;
  };

  function mountComponent() {
    wrapper = shallowMount(ErrorDetails, {
      stubs: { LoadingButton },
      localVue,
      store,
      mocks,
      propsData: {
        issueId: '123',
        projectPath: '/root/gitlab-test',
        issueDetailsPath: '/123/details',
        issueStackTracePath: '/stacktrace',
        projectIssuesPath: '/test-project/issues/',
        csrfToken: 'fakeToken',
      },
    });
    wrapper.setData({
      GQLerror: {
        id: 129381,
        title: 'Issue title',
        externalUrl: 'http://sentry.gitlab.net/gitlab',
        firstSeen: '2017-05-26T13:32:48Z',
        lastSeen: '2018-05-26T13:32:48Z',
        count: 12,
        userCount: 2,
      },
    });
  }

  beforeEach(() => {
    actions = {
      startPollingDetails: () => {},
      startPollingStacktrace: () => {},
    };

    getters = {
      sentryUrl: () => 'sentry.io',
      stacktrace: () => [{ context: [1, 2], lineNo: 53, filename: 'index.js' }],
    };

    const state = {
      error: {},
      loading: true,
      stacktraceData: {},
      loadingStacktrace: true,
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
          GQLerror: {
            loading: true,
            stopPolling: jest.fn(),
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

  describe('Error details', () => {
    beforeEach(() => {
      store.state.details.loading = false;
      store.state.details.error.id = 1;
      mocks.$apollo.queries.GQLerror.loading = false;
      mountComponent();
    });

    it('should show Sentry error details without stacktrace', () => {
      expect(wrapper.find(GlLink).exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
      expect(wrapper.find(GlBadge).exists()).toBe(false);
    });

    describe('Badges', () => {
      it('should show language and error level badges', () => {
        store.state.details.error.tags = { level: 'error', logger: 'ruby' };
        mountComponent();
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlBadge).length).toBe(2);
        });
      });

      it('should NOT show the badge if the tag is not present', () => {
        store.state.details.error.tags = { level: 'error' };
        mountComponent();
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlBadge).length).toBe(1);
        });
      });
    });

    describe('Stacktrace', () => {
      it('should show stacktrace', () => {
        store.state.details.loadingStacktrace = false;
        mountComponent();
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.find(Stacktrace).exists()).toBe(true);
        });
      });

      it('should NOT show stacktrace if no entries', () => {
        store.state.details.loadingStacktrace = false;
        store.getters = { 'details/sentryUrl': () => 'sentry.io', 'details/stacktrace': () => [] };
        mountComponent();
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.find(Stacktrace).exists()).toBe(false);
      });
    });

    describe('When a user clicks the create issue button', () => {
      beforeEach(() => {
        mountComponent();
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
        wrapper.find('button').trigger('click');
        expect(submitSpy).toHaveBeenCalled();
        submitSpy.mockRestore();
      });
    });

    describe('GitLab issue link', () => {
      const gitlabIssue = 'https://gitlab.example.com/issues/1';
      const findGitLabLink = () => wrapper.find(`[href="${gitlabIssue}"]`);
      const findCreateIssueButton = () => wrapper.find('[data-qa-selector="create_issue_button"]');

      describe('is present', () => {
        beforeEach(() => {
          store.state.details.loading = false;
          store.state.details.error = {
            id: 1,
            gitlab_issue: gitlabIssue,
          };
          mountComponent();
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
          store.state.details.loading = false;
          store.state.details.error = {
            id: 1,
            gitlab_issue: null,
          };
          mountComponent();
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
});
