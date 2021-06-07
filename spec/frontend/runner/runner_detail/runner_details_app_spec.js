import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerTypeBadge from '~/runner/components/runner_type_badge.vue';
import getRunnerQuery from '~/runner/graphql/get_runner.query.graphql';
import RunnerDetailsApp from '~/runner/runner_details/runner_details_app.vue';

import { runnerData } from '../mock_data';

const mockRunnerGraphqlId = runnerData.data.runner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('RunnerDetailsApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerTypeBadge = () => wrapper.findComponent(RunnerTypeBadge);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    const handlers = [[getRunnerQuery, mockRunnerQuery]];

    wrapper = mountFn(RunnerDetailsApp, {
      localVue,
      apolloProvider: createMockApollo(handlers),
      propsData: {
        runnerId: mockRunnerId,
        ...props,
      },
    });

    return waitForPromises();
  };

  beforeEach(async () => {
    mockRunnerQuery = jest.fn().mockResolvedValue(runnerData);
  });

  afterEach(() => {
    mockRunnerQuery.mockReset();
    wrapper.destroy();
  });

  it('expect GraphQL ID to be requested', async () => {
    await createComponentWithApollo();

    expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
  });

  it('displays the runner id', async () => {
    await createComponentWithApollo();

    expect(wrapper.text()).toContain(`Runner #${mockRunnerId}`);
  });

  it('displays the runner type', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerTypeBadge().text()).toBe('shared');
  });
});
