import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import AssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import issuableAssigneesSubscription from '~/sidebar/queries/issuable_assignees.subscription.graphql';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import getIssueAssigneesQuery from '~/vue_shared/components/sidebar/queries/get_issue_assignees.query.graphql';
import Mock, { issuableQueryResponse, subscriptionNullResponse } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Assignees Realtime', () => {
  let wrapper;
  let mediator;
  let fakeApollo;

  const issuableQueryHandler = jest.fn().mockResolvedValue(issuableQueryResponse);
  const subscriptionInitialHandler = jest.fn().mockResolvedValue(subscriptionNullResponse);

  const createComponent = ({
    issuableType = 'issue',
    issuableId = 1,
    subscriptionHandler = subscriptionInitialHandler,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getIssueAssigneesQuery, issuableQueryHandler],
      [issuableAssigneesSubscription, subscriptionHandler],
    ]);
    wrapper = shallowMount(AssigneesRealtime, {
      propsData: {
        issuableType,
        issuableId,
        queryVariables: {
          issuableIid: '1',
          projectPath: 'path/to/project',
        },
        mediator,
      },
      apolloProvider: fakeApollo,
      localVue,
    });
  };

  beforeEach(() => {
    mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
    SidebarMediator.singleton = null;
  });

  it('calls the query with correct variables', () => {
    createComponent();

    expect(issuableQueryHandler).toHaveBeenCalledWith({
      issuableIid: '1',
      projectPath: 'path/to/project',
    });
  });

  it('calls the subscription with correct variable for issue', () => {
    createComponent();

    expect(subscriptionInitialHandler).toHaveBeenCalledWith({
      issuableId: 'gid://gitlab/Issue/1',
    });
  });
});
