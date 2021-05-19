import * as Sentry from '@sentry/browser';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RunnerList from '~/runner/components/runner_list.vue';
import RunnerManualSetupHelp from '~/runner/components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';

import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import RunnerListApp from '~/runner/runner_list/runner_list_app.vue';

import { runnersData } from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
const mockActiveRunnersCount = 2;
const mocKRunners = runnersData.data.runners.nodes;

jest.mock('@sentry/browser');

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('RunnerListApp', () => {
  let wrapper;
  let mockRunnersQuery;

  const findRunnerTypeHelp = () => wrapper.findComponent(RunnerTypeHelp);
  const findRunnerManualSetupHelp = () => wrapper.findComponent(RunnerManualSetupHelp);
  const findRunnerList = () => wrapper.findComponent(RunnerList);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    const handlers = [[getRunnersQuery, mockRunnersQuery]];

    wrapper = mountFn(RunnerListApp, {
      localVue,
      apolloProvider: createMockApollo(handlers),
      propsData: {
        activeRunnersCount: mockActiveRunnersCount,
        registrationToken: mockRegistrationToken,
        ...props,
      },
    });
  };

  beforeEach(async () => {
    Sentry.withScope.mockImplementation((fn) => {
      const scope = { setTag: jest.fn() };
      fn(scope);
    });

    mockRunnersQuery = jest.fn().mockResolvedValue(runnersData);
    createComponentWithApollo();
    await waitForPromises();
  });

  afterEach(() => {
    mockRunnersQuery.mockReset();
    wrapper.destroy();
  });

  it('shows the runners list', () => {
    expect(mocKRunners).toMatchObject(findRunnerList().props('runners'));
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    expect(findRunnerManualSetupHelp().exists()).toBe(true);
    expect(findRunnerManualSetupHelp().props('registrationToken')).toBe(mockRegistrationToken);
  });

  describe('when no runners are found', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockResolvedValue({ data: { runners: { nodes: [] } } });
      createComponentWithApollo();
      await waitForPromises();
    });

    it('shows a message for no results', async () => {
      expect(wrapper.text()).toContain('No runners found');
    });
  });

  it('when runners have not loaded, shows a loading state', () => {
    createComponentWithApollo();
    expect(findRunnerList().props('loading')).toBe(true);
  });

  describe('when runners query fails', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockRejectedValue(new Error());
      createComponentWithApollo();

      await waitForPromises();
    });

    it('error is reported to sentry', async () => {
      expect(Sentry.withScope).toHaveBeenCalled();
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });
});
