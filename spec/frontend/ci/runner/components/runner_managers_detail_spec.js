import { GlTableLite } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RunnerManagersDetail from '~/ci/runner/components/runner_managers_detail.vue';
import RunnerManagersTable from '~/ci/runner/components/runner_managers_table.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

import runnerManagersQuery from '~/ci/runner/graphql/show/runner_managers.query.graphql';
import { runnerData, runnerManagersData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerManagers = runnerManagersData.data.runner.managers.nodes;

Vue.use(VueApollo);

describe('RunnerJobs', () => {
  let wrapper;
  let mockRunnerManagersHandler;

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findCrudExpandToggle = () => wrapper.findByTestId('crud-collapse-toggle');
  const findRunnerManagersTable = () => wrapper.findComponent(RunnerManagersTable);

  const createComponent = ({ props, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerManagersDetail, {
      apolloProvider: createMockApollo([[runnerManagersQuery, mockRunnerManagersHandler]]),
      propsData: {
        runner: mockRunner,
        ...props,
      },
      stubs: {
        GlTableLite,
        CrudComponent,
      },
    });
  };

  beforeEach(() => {
    mockRunnerManagersHandler = jest.fn();
  });

  afterEach(() => {
    mockRunnerManagersHandler.mockReset();
  });

  it('hides if no runners', () => {
    createComponent({
      props: {
        runner: {
          managers: {
            count: 0,
          },
        },
      },
    });

    expect(findCrudComponent().exists()).toBe(false);
  });

  describe('Runners count', () => {
    it.each`
      count   | expected
      ${1}    | ${'1'}
      ${1000} | ${'1,000'}
    `('displays runner managers count of $count', ({ count, expected }) => {
      createComponent({
        mountFn: mountExtended,
        props: {
          runner: {
            ...mockRunner,
            managers: {
              count,
            },
          },
        },
      });

      expect(findCrudComponent().props('count')).toBe(expected);
    });
  });

  describe('Shows data', () => {
    beforeEach(async () => {
      mockRunnerManagersHandler.mockResolvedValue(runnerManagersData);

      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('fetches data', () => {
      expect(mockRunnerManagersHandler).toHaveBeenCalledTimes(1);
      expect(mockRunnerManagersHandler).toHaveBeenCalledWith({
        runnerId: mockRunner.id,
      });
    });

    it('shows rows', async () => {
      await findCrudExpandToggle().vm.$emit('click');

      expect(findRunnerManagersTable().props('items')).toEqual(mockRunnerManagers);
    });
  });
});
