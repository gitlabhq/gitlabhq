import { GlBanner } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import PipelineNotification from '~/pipelines/components/notification/pipeline_notification.vue';
import getUserCallouts from '~/pipelines/graphql/queries/get_user_callouts.query.graphql';

describe('Pipeline notification', () => {
  const localVue = createLocalVue();

  let wrapper;
  const dagDocPath = 'my/dag/path';

  const createWrapper = (apolloProvider) => {
    return shallowMount(PipelineNotification, {
      localVue,
      provide: {
        dagDocPath,
      },
      apolloProvider,
    });
  };

  const createWrapperWithApollo = async ({ callouts = [], isLoading = false } = {}) => {
    localVue.use(VueApollo);

    const mappedCallouts = callouts.map((callout) => {
      return { featureName: callout, __typename: 'UserCallout' };
    });

    const mockCalloutsResponse = {
      data: {
        currentUser: {
          id: 45,
          __typename: 'User',
          callouts: {
            id: 5,
            __typename: 'UserCalloutConnection',
            nodes: mappedCallouts,
          },
        },
      },
    };
    const getUserCalloutsHandler = jest.fn().mockResolvedValue(mockCalloutsResponse);
    const requestHandlers = [[getUserCallouts, getUserCalloutsHandler]];

    const apolloWrapper = createWrapper(createMockApollo(requestHandlers));
    if (!isLoading) {
      await nextTick();
    }

    return apolloWrapper;
  };

  const findBanner = () => wrapper.findComponent(GlBanner);

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows the banner if the user has never seen it', async () => {
    wrapper = await createWrapperWithApollo({ callouts: ['random'] });

    expect(findBanner().exists()).toBe(true);
  });

  it('does not show the banner while the user callout query is loading', async () => {
    wrapper = await createWrapperWithApollo({ callouts: ['random'], isLoading: true });

    expect(findBanner().exists()).toBe(false);
  });

  it('does not show the banner if the user has previously dismissed it', async () => {
    wrapper = await createWrapperWithApollo({ callouts: ['pipeline_needs_banner'.toUpperCase()] });

    expect(findBanner().exists()).toBe(false);
  });
});
