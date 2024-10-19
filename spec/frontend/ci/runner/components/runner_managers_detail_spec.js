import { GlCollapse, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RunnerManagersDetail from '~/ci/runner/components/runner_managers_detail.vue';
import RunnerManagersTable from '~/ci/runner/components/runner_managers_table.vue';

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

  const findDetails = () => wrapper.findByTestId('runner-button');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const findCollapse = () => wrapper.findComponent(GlCollapse);
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
      },
    });
  };

  beforeEach(() => {
    mockRunnerManagersHandler = jest.fn();
  });

  afterEach(() => {
    mockRunnerManagersHandler.mockReset();
  });

  describe('Runners count', () => {
    it.each`
      count   | expected
      ${0}    | ${'0'}
      ${1}    | ${'1'}
      ${1000} | ${'1,000'}
    `('displays runner managers count of $count', ({ count, expected }) => {
      createComponent({
        props: {
          runner: {
            ...mockRunner,
            managers: {
              count,
            },
          },
        },
      });

      expect(wrapper.text()).toContain(expected);
    });
  });

  describe('Expand and collapse', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows link to expand', () => {
      expect(findDetails().exists()).toBe(true);
      expect(findDetails().text()).toBe('Show details');
    });

    it('is collapsed', () => {
      expect(findCollapse().props('visible')).toBe(false);
    });

    describe('when expanded', () => {
      beforeEach(() => {
        findDetails().vm.$emit('click');
      });

      it('shows link to collapse', () => {
        expect(findDetails().exists()).toBe(true);
        expect(findDetails().text()).toBe('Hide details');
      });

      it('shows loading state', () => {
        expect(findCollapse().props('visible')).toBe(true);
        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('fetches data', () => {
        expect(mockRunnerManagersHandler).toHaveBeenCalledTimes(1);
        expect(mockRunnerManagersHandler).toHaveBeenCalledWith({
          runnerId: mockRunner.id,
        });
      });
    });
  });

  describe('Prefetches data upon user interation', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not fetch initially', () => {
      expect(mockRunnerManagersHandler).not.toHaveBeenCalled();
    });

    describe.each(['focus', 'mouseover'])('fetches data after %s', (event) => {
      beforeEach(() => {
        findDetails().vm.$emit(event);
      });

      it('fetches data', () => {
        expect(mockRunnerManagersHandler).toHaveBeenCalledTimes(1);
        expect(mockRunnerManagersHandler).toHaveBeenCalledWith({
          runnerId: mockRunner.id,
        });
      });

      it('fetches data only once', async () => {
        findDetails().vm.$emit(event);
        await waitForPromises();

        expect(mockRunnerManagersHandler).toHaveBeenCalledTimes(1);
        expect(mockRunnerManagersHandler).toHaveBeenCalledWith({
          runnerId: mockRunner.id,
        });
      });
    });
  });

  describe('Shows data', () => {
    beforeEach(async () => {
      mockRunnerManagersHandler.mockResolvedValue(runnerManagersData);

      createComponent({ mountFn: mountExtended });

      await findDetails().trigger('click');
    });

    it('shows rows', () => {
      expect(findCollapse().props('visible')).toBe(true);
      expect(findRunnerManagersTable().props('items')).toEqual(mockRunnerManagers);
    });

    it('collapses when clicked', async () => {
      await findDetails().trigger('click');

      expect(findCollapse().props('visible')).toBe(false);
    });
  });
});
