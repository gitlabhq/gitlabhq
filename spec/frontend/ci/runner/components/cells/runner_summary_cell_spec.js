import { GlSprintf } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerSummaryCell from '~/ci/runner/components/cells/runner_summary_cell.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RunnerCreatedAt from '~/ci/runner/components/runner_created_at.vue';
import RunnerJobCount from '~/ci/runner/components/runner_job_count.vue';
import RunnerManagersBadge from '~/ci/runner/components/runner_managers_badge.vue';
import RunnerTags from '~/ci/runner/components/runner_tags.vue';
import RunnerSummaryField from '~/ci/runner/components/cells/runner_summary_field.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import { INSTANCE_TYPE, I18N_INSTANCE_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

import { allRunnersWithCreatorData } from '../../mock_data';

const mockRunner = allRunnersWithCreatorData.data.runners.nodes[0];

describe('RunnerTypeCell', () => {
  let wrapper;

  const findRunnerManagersBadge = () => wrapper.findComponent(RunnerManagersBadge);
  const findLockIcon = () => wrapper.findByTestId('lock-icon');
  const findRunnerTags = () => wrapper.findComponent(RunnerTags);
  const findRunnerSummaryField = (icon) =>
    wrapper.findAllComponents(RunnerSummaryField).wrappers.find((w) => w.props('icon') === icon);

  const createComponent = ({ runner, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerSummaryCell, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
      },
      stubs: {
        GlSprintf,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Displays the runner name as id and short token', () => {
    createComponent({ mountFn: mountExtended });

    expect(wrapper.text()).toContain(
      `#${getIdFromGraphQLId(mockRunner.id)} (${mockRunner.shortSha})`,
    );
  });

  it('Displays no runner manager count', () => {
    createComponent({
      runner: { managers: { nodes: { count: 0 } } },
      mountFn: mountExtended,
    });

    expect(findRunnerManagersBadge().find('*').exists()).toBe(false);
  });

  it('Displays runner manager count', () => {
    createComponent({ mountFn: mountExtended });

    expect(findRunnerManagersBadge().text()).toBe('2');
  });

  it('Does not display the locked icon', () => {
    expect(findLockIcon().exists()).toBe(false);
  });

  it('Displays the locked icon for locked runners', () => {
    createComponent({
      runner: { runnerType: PROJECT_TYPE, locked: true },
      mountFn: mountExtended,
    });

    expect(findLockIcon().exists()).toBe(true);
  });

  it('Displays the runner type', () => {
    createComponent({
      runner: { runnerType: INSTANCE_TYPE, locked: true },
      mountFn: mountExtended,
    });

    expect(wrapper.text()).toContain(I18N_INSTANCE_TYPE);
  });

  it('Displays the runner version', () => {
    expect(wrapper.text()).toContain(mockRunner.managers.nodes[0].version);
  });

  it('Displays the runner description', () => {
    expect(wrapper.text()).toContain(mockRunner.description);
  });

  it('Displays last contact', () => {
    createComponent({
      runner: { contactedAt: '2022-01-02' },
    });

    expect(findRunnerSummaryField('clock').findComponent(TimeAgo).props('time')).toBe('2022-01-02');
  });

  it('Displays empty last contact', () => {
    createComponent({
      contactedAt: null,
    });

    expect(findRunnerSummaryField('clock').findComponent(TimeAgo).exists()).toBe(false);
    expect(findRunnerSummaryField('clock').text()).toContain('Never');
  });

  describe('IP address', () => {
    it('with no managers', () => {
      createComponent({
        runner: {
          managers: { count: 0, nodes: [] },
        },
      });

      expect(findRunnerSummaryField('disk')).toBeUndefined();
    });

    it('with no ip', () => {
      createComponent({
        runner: {
          managers: { count: 1, nodes: [{ ipAddress: null }] },
        },
      });

      expect(findRunnerSummaryField('disk')).toBeUndefined();
    });

    it.each`
      count   | ipAddress      | expected
      ${1}    | ${'127.0.0.1'} | ${'127.0.0.1'}
      ${2}    | ${'127.0.0.2'} | ${'127.0.0.2 (+1)'}
      ${11}   | ${'127.0.0.3'} | ${'127.0.0.3 (+10)'}
      ${1001} | ${'127.0.0.4'} | ${'127.0.0.4 (+1,000)'}
    `(
      'with $count managers, ip $ipAddress displays $expected',
      ({ count, ipAddress, expected }) => {
        createComponent({
          runner: {
            // `first: 1` is requested, `count` varies when there are more managers
            managers: { count, nodes: [{ ipAddress }] },
          },
        });

        expect(findRunnerSummaryField('disk').text()).toMatchInterpolatedText(expected);
      },
    );
  });

  it('Displays job count', () => {
    expect(
      findRunnerSummaryField('pipeline').findComponent(RunnerJobCount).props('runner'),
    ).toEqual(mockRunner);
  });

  it('Displays creation info', () => {
    createComponent();

    const createdAt = findRunnerSummaryField('calendar').findComponent(RunnerCreatedAt);
    expect(createdAt.props('runner')).toEqual(mockRunner);
  });

  it('Displays tag list', () => {
    createComponent({
      runner: { tagList: ['shell', 'linux'] },
    });

    expect(findRunnerTags().props('tagList')).toEqual(['shell', 'linux']);
  });

  it('Displays a custom runner-name slot', () => {
    const slotContent = 'My custom runner name';

    createComponent({
      slots: {
        'runner-name': slotContent,
      },
    });

    expect(wrapper.text()).toContain(slotContent);
  });
});
