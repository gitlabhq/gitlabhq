import { GlButton, GlAvatarLink, GlTooltip, GlLoadingIcon } from '@gitlab/ui';
import { createMockSubscription } from 'mock-apollo-client';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import JobHeader from '~/ci/job_details/components/job_header.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import getJobQuery from '~/ci/job_details/graphql/queries/get_job.query.graphql';
import jobCiStatusUpdatedSubscription from '~/ci/job_details/graphql/subscriptions/job_ci_status_updated.subscription.graphql';
import { mockJobResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Header CI Component', () => {
  let wrapper;
  let apolloProvider;
  let mockSubscription;
  let subscriptionHandler;

  const defaultProps = {
    jobId: 13051,
    user: {
      id: 1234,
      web_url: 'path',
      name: 'Foo',
      username: 'foobar',
      email: 'foo@bar.com',
      avatar_url: 'link',
    },
  };

  const successHandler = jest.fn().mockResolvedValue(mockJobResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findTimeAgo = () => wrapper.findComponent(TimeagoTooltip);
  const findUserLink = () => wrapper.findComponent(GlAvatarLink);
  const findSidebarToggleBtn = () => wrapper.findComponent(GlButton);
  const findStatusTooltip = () => wrapper.findComponent(GlTooltip);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findJobName = () => wrapper.findByTestId('job-name');

  const defaultHandlers = [[getJobQuery, successHandler]];

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (props, handlers = defaultHandlers, flagEnabled = true) => {
    mockSubscription = createMockSubscription();
    subscriptionHandler = jest.fn().mockReturnValue(mockSubscription);
    apolloProvider = createMockApolloProvider(handlers);

    apolloProvider.defaultClient.setRequestHandler(
      jobCiStatusUpdatedSubscription,
      subscriptionHandler,
    );

    wrapper = shallowMountExtended(JobHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        projectPath: 'gitlab-org/gitlab',
        glFeatures: {
          ciJobStatusRealtime: flagEnabled,
        },
      },
      apolloProvider,
    });
  };

  describe('loading', () => {
    it('should display a loading icon', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('render', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('should not display a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the correct job name', () => {
      expect(findJobName().text()).toBe('artifact_job');
    });

    it('should render status badge', () => {
      expect(findCiIcon().exists()).toBe(true);
    });

    it('should render timeago date', () => {
      expect(findTimeAgo().exists()).toBe(true);
    });

    it('should render sidebar toggle button', () => {
      expect(findSidebarToggleBtn().exists()).toBe(true);
    });

    it('calls query with correct variables', () => {
      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        id: 'gid://gitlab/Ci::Build/13051',
      });
    });
  });

  describe('user avatar', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('contains the username', () => {
      expect(findUserLink().text()).toContain(defaultProps.user.username);
    });

    it('has the correct HTML attributes', () => {
      expect(findUserLink().attributes()).toMatchObject({
        'data-user-id': defaultProps.user.id.toString(),
        'data-username': defaultProps.user.username,
        'data-name': defaultProps.user.name,
        href: defaultProps.user.web_url,
      });
    });

    describe('when the user has a status', () => {
      const STATUS_MESSAGE = 'Working on exciting features...';

      beforeEach(async () => {
        createComponent({
          user: { ...defaultProps.user, status: { message: STATUS_MESSAGE } },
        });

        await waitForPromises();
      });

      it('renders a tooltip', () => {
        expect(findStatusTooltip().text()).toBe(STATUS_MESSAGE);
      });
    });

    describe('with data from GraphQL', () => {
      const userId = 1;

      beforeEach(async () => {
        createComponent({
          user: { ...defaultProps.user, id: `gid://gitlab/User/${1}` },
        });

        await waitForPromises();
      });

      it('has the correct user id', () => {
        expect(findUserLink().attributes('data-user-id')).toBe(userId.toString());
      });
    });

    describe('with data from REST', () => {
      it('has the correct user id', () => {
        expect(findUserLink().attributes('data-user-id')).toBe(defaultProps.user.id.toString());
      });
    });
  });

  describe('triggered label', () => {
    it('should render created keyword', async () => {
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toContain('Created');
      expect(wrapper.text()).not.toContain('Started');
    });
  });

  describe('real time updates', () => {
    describe('with ciJobStatusRealtime enabled', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('updates job status', async () => {
        expect(findCiIcon().props('status')).toEqual({
          __typename: 'DetailedStatus',
          detailsPath: '/root/ci-project/-/jobs/13051',
          icon: 'status_success',
          id: 'success-13051-13051',
          text: 'Passed',
        });

        mockSubscription.next({
          data: {
            ciJobStatusUpdated: {
              id: 'gid://gitlab/Ci::Build/389',
              detailedStatus: {
                __typename: 'DetailedStatus',
                detailsPath: '/root/ci-project/-/jobs/389',
                icon: 'status_running',
                id: 'running-389-389',
                text: 'Running',
              },
            },
          },
        });

        await waitForPromises();

        expect(subscriptionHandler).toHaveBeenCalledWith({ jobId: 'gid://gitlab/Ci::Build/13051' });
        expect(findCiIcon().props('status')).toEqual({
          __typename: 'DetailedStatus',
          id: 'running-389-389',
          icon: 'status_running',
          text: 'Running',
          detailsPath: '/root/ci-project/-/jobs/389',
        });
      });
    });

    describe('with ciJobStatusRealtime disabled', () => {
      beforeEach(async () => {
        createComponent({}, defaultHandlers, false);

        await waitForPromises();
      });

      it('updates job status', () => {
        expect(subscriptionHandler).not.toHaveBeenCalled();
      });
    });
  });

  describe('error', () => {
    beforeEach(async () => {
      createComponent(defaultProps, [[getJobQuery, failedHandler]]);

      await waitForPromises();
    });

    it('shows error alert on GraphQL error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Error),
        message: 'An error occurred while fetching the job header data.',
      });
    });

    it('does not call the graphql subscription when there is no job data', () => {
      expect(subscriptionHandler).not.toHaveBeenCalled();
    });
  });
});
