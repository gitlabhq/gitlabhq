import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import issuableAssigneesSubscription from '~/sidebar/queries/issuable_assignees.subscription.graphql';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import getIssueAssigneesQuery from '~/sidebar/queries/get_issue_assignees.query.graphql';
import Mock, {
  issuableQueryResponse,
  subscriptionNullResponse,
  subscriptionResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('Assignees Realtime', () => {
  let wrapper;
  let mediator;
  let fakeApollo;

  const issuableQueryHandler = jest.fn().mockResolvedValue(issuableQueryResponse);
  const subscriptionInitialHandler = jest.fn().mockResolvedValue(subscriptionNullResponse);

  const createComponent = ({
    issuableType = 'issue',
    subscriptionHandler = subscriptionInitialHandler,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getIssueAssigneesQuery, issuableQueryHandler],
      [issuableAssigneesSubscription, subscriptionHandler],
    ]);
    wrapper = shallowMount(AssigneesRealtime, {
      propsData: {
        issuableType,
        queryVariables: {
          issuableIid: '1',
          projectPath: 'path/to/project',
        },
        mediator,
      },
      apolloProvider: fakeApollo,
    });
  };

  beforeEach(() => {
    mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
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

  it('calls the subscription with correct variable for issue', async () => {
    createComponent();
    await waitForPromises();

    expect(subscriptionInitialHandler).toHaveBeenCalledWith({
      issuableId: 'gid://gitlab/Issue/1',
    });
  });

  it('emits an `assigneesUpdated` event on subscription response', async () => {
    createComponent({
      subscriptionHandler: jest.fn().mockResolvedValue(subscriptionResponse),
    });
    await waitForPromises();

    expect(wrapper.emitted('assigneesUpdated')).toEqual([
      [{ id: '1', assignees: subscriptionResponse.data.issuableAssigneesUpdated.assignees.nodes }],
    ]);
  });
});
