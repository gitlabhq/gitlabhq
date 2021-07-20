import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerTypeBadge from '~/runner/components/runner_type_badge.vue';
import getRunnerQuery from '~/runner/graphql/get_runner.query.graphql';
import RunnerDetailsApp from '~/runner/runner_details/runner_details_app.vue';
import { captureException } from '~/runner/sentry_utils';

import { runnerData } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const mockRunnerGraphqlId = runnerData.data.runner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('RunnerDetailsApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerTypeBadge = () => wrapper.findComponent(RunnerTypeBadge);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerDetailsApp, {
      localVue,
      apolloProvider: createMockApollo([[getRunnerQuery, mockRunnerQuery]]),
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

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponentWithApollo();
    });

    it('error is reported to sentry', async () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Network error: Error!'),
        component: 'RunnerDetailsApp',
      });
    });

    it('error is shown to the user', async () => {
      expect(createFlash).toHaveBeenCalled();
    });
  });
});
