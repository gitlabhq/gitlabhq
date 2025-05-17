import { GlTableLite } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RunnerManagers from '~/ci/runner/components/runner_managers.vue';
import RunnerManagersTable from '~/ci/runner/components/runner_managers_table.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

import { runnerData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerManagers = runnerData.data.runner.managers.nodes;

describe('RunnerJobs', () => {
  let wrapper;

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findCrudExpandToggle = () => wrapper.findByTestId('crud-collapse-toggle');
  const findRunnerManagersTable = () => wrapper.findComponent(RunnerManagersTable);

  const createComponent = ({ props, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerManagers, {
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

  it('hides if no runners', () => {
    createComponent({
      props: {
        runner: {
          ...mockRunner,
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
      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('shows rows', async () => {
      await findCrudExpandToggle().vm.$emit('click');

      expect(findRunnerManagersTable().props('items')).toEqual(mockRunnerManagers);
    });
  });
});
