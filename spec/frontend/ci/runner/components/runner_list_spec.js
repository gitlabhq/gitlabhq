import { GlTableLite, GlSkeletonLoader } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createLocalState } from '~/ci/runner/graphql/list/local_state';
import { stubComponent } from 'helpers/stub_component';

import RunnerList from '~/ci/runner/components/runner_list.vue';
import RunnerBulkDelete from '~/ci/runner/components/runner_bulk_delete.vue';
import RunnerBulkDeleteCheckbox from '~/ci/runner/components/runner_bulk_delete_checkbox.vue';
import RunnerConfigurationPopover from '~/ci/runner/components/runner_configuration_popover.vue';

import { I18N_PROJECT_TYPE, I18N_STATUS_NEVER_CONTACTED } from '~/ci/runner/constants';
import { allRunnersData } from '../mock_data';

const mockRunners = allRunnersData.data.runners.nodes;

describe('RunnerList', () => {
  let wrapper;
  let cacheConfig;
  let localMutations;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findHeaders = () => wrapper.findAll('th');
  const findRows = () => wrapper.findAll('[data-testid^="runner-row-"]');
  const findCell = ({ row = 0, fieldKey }) =>
    findRows().at(row).find(`[data-testid="td-${fieldKey}"]`);
  const findRunnerBulkDelete = () => wrapper.findComponent(RunnerBulkDelete);
  const findRunnerBulkDeleteCheckbox = () => wrapper.findComponent(RunnerBulkDeleteCheckbox);

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMountExtended) => {
    ({ cacheConfig, localMutations } = createLocalState());

    wrapper = mountFn(RunnerList, {
      apolloProvider: createMockApollo([], {}, cacheConfig),
      propsData: {
        runners: mockRunners,
        ...props,
      },
      provide: {
        localMutations,
      },
      ...options,
    });
  };

  it('Displays headers', () => {
    createComponent(
      {
        stubs: {
          HelpPopover: {
            template: '<div/>',
          },
        },
      },
      mountExtended,
    );

    const headers = findHeaders().wrappers;

    expect(headers).toHaveLength(4);

    expect(headers[0].text()).toBe('Status');

    expect(headers[1].findComponent(RunnerConfigurationPopover).exists()).toBe(true);
    expect(headers[1].text()).toBe('Runner configuration');

    expect(headers[2].findComponent(HelpPopover).exists()).toBe(true);
    expect(headers[2].text()).toBe('Owner');

    expect(headers[3].text()).toBe(''); // actions has no label
  });

  it('Sets runner id as a row key', () => {
    createComponent({
      stubs: {
        GlTableLite: stubComponent(GlTableLite),
      },
    });

    expect(findTable().attributes('primary-key')).toBe('id');
  });

  it('Displays a list of runners', () => {
    createComponent({}, mountExtended);

    expect(findRows()).toHaveLength(4);

    expect(findSkeletonLoader().exists()).toBe(false);
  });

  it('Displays details of a runner', () => {
    createComponent({}, mountExtended);

    const { id, description, shortSha } = mockRunners[0];

    const numericId = getIdFromGraphQLId(id);

    // Badges
    expect(findCell({ fieldKey: 'status' }).text()).toMatchInterpolatedText(
      I18N_STATUS_NEVER_CONTACTED,
    );

    // Runner summary
    const summary = findCell({ fieldKey: 'summary' }).text();

    expect(summary).toContain(`#${numericId} (${shortSha})`);
    expect(summary).toContain(I18N_PROJECT_TYPE);

    expect(summary).toContain(description);

    expect(summary).toContain('Last contact');
    expect(summary).toContain('-'); // job count
    expect(summary).toContain('Created');

    // Actions
    expect(findCell({ fieldKey: 'actions' }).exists()).toBe(true);
  });

  describe('When the list is checkable', () => {
    beforeEach(() => {
      createComponent(
        {
          props: {
            checkable: true,
          },
        },
        mountExtended,
      );
    });

    it('runner bulk delete is available', () => {
      expect(findRunnerBulkDelete().props('runners')).toEqual(mockRunners);
    });

    it('runner bulk delete checkbox is available', () => {
      expect(findRunnerBulkDeleteCheckbox().props('runners')).toEqual(mockRunners);
    });

    it('Displays a checkbox field', () => {
      expect(findCell({ fieldKey: 'checkbox' }).find('input').exists()).toBe(true);
    });

    it('Sets a runner as checked', async () => {
      const runner = mockRunners[0];
      const setRunnerCheckedMock = jest
        .spyOn(localMutations, 'setRunnerChecked')
        .mockImplementation(() => {});

      const checkbox = findCell({ fieldKey: 'checkbox' }).find('input');
      await checkbox.setChecked();

      expect(setRunnerCheckedMock).toHaveBeenCalledTimes(1);
      expect(setRunnerCheckedMock).toHaveBeenCalledWith({
        runner,
        isChecked: true,
      });
    });

    it('Emits a deleted event', () => {
      const event = { message: 'Deleted!' };
      findRunnerBulkDelete().vm.$emit('deleted', event);

      expect(wrapper.emitted('deleted')).toEqual([[event]]);
    });
  });

  describe('Scoped cell slots', () => {
    it('Render #runner-job-status-badge slot in "status" cell', () => {
      createComponent(
        {
          scopedSlots: {
            'runner-job-status-badge': ({ runner }) => `Job status ${runner.jobExecutionStatus}`,
          },
        },
        mountExtended,
      );

      expect(findCell({ fieldKey: 'status' }).text()).toContain(
        `Job status ${mockRunners[0].jobExecutionStatus}`,
      );
    });

    it('Render #runner-name slot in "summary" cell', () => {
      createComponent(
        {
          scopedSlots: { 'runner-name': ({ runner }) => `Summary: ${runner.id}` },
        },
        mountExtended,
      );

      expect(findCell({ fieldKey: 'summary' }).text()).toContain(`Summary: ${mockRunners[0].id}`);
    });

    it('Render #runner-actions-cell slot in "actions" cell', () => {
      createComponent(
        {
          scopedSlots: { 'runner-actions-cell': ({ runner }) => `Actions: ${runner.id}` },
        },
        mountExtended,
      );

      expect(findCell({ fieldKey: 'actions' }).text()).toBe(`Actions: ${mockRunners[0].id}`);
    });
  });

  it('Shows runner identifier', () => {
    const { id, shortSha } = mockRunners[0];
    const numericId = getIdFromGraphQLId(id);

    createComponent({}, mountExtended);

    expect(findCell({ fieldKey: 'summary' }).text()).toContain(`#${numericId} (${shortSha})`);
  });

  describe('When data is loading', () => {
    it('shows a busy state', () => {
      createComponent({
        props: { runners: [], loading: true },
        stubs: {
          GlTableLite: stubComponent(GlTableLite),
        },
      });

      expect(findTable().classes('gl-opacity-6')).toBe(true);
    });

    it('when there are no runners, shows an skeleton loader', () => {
      createComponent({ props: { runners: [], loading: true } }, mountExtended);

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('when there are runners, shows a busy indicator skeleton loader', () => {
      createComponent({ props: { loading: true } }, mountExtended);

      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
