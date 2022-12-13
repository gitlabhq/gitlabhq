import { __ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerSummaryCell from '~/ci/runner/components/cells/runner_summary_cell.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RunnerTags from '~/ci/runner/components/runner_tags.vue';
import RunnerJobStatusBadge from '~/ci/runner/components/runner_job_status_badge.vue';
import RunnerSummaryField from '~/ci/runner/components/cells/runner_summary_field.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import {
  INSTANCE_TYPE,
  I18N_INSTANCE_TYPE,
  PROJECT_TYPE,
  I18N_NO_DESCRIPTION,
} from '~/ci/runner/constants';

import { allRunnersData } from '../../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

describe('RunnerTypeCell', () => {
  let wrapper;

  const findLockIcon = () => wrapper.findByTestId('lock-icon');
  const findRunnerJobStatusBadge = () => wrapper.findComponent(RunnerJobStatusBadge);
  const findRunnerTags = () => wrapper.findComponent(RunnerTags);
  const findRunnerSummaryField = (icon) =>
    wrapper.findAllComponents(RunnerSummaryField).filter((w) => w.props('icon') === icon)
      .wrappers[0];

  const createComponent = (runner, options) => {
    wrapper = mountExtended(RunnerSummaryCell, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
      },
      stubs: {
        RunnerSummaryField,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays the runner name as id and short token', () => {
    expect(wrapper.text()).toContain(
      `#${getIdFromGraphQLId(mockRunner.id)} (${mockRunner.shortSha})`,
    );
  });

  it('Does not display the locked icon', () => {
    expect(findLockIcon().exists()).toBe(false);
  });

  it('Displays the locked icon for locked runners', () => {
    createComponent({
      runnerType: PROJECT_TYPE,
      locked: true,
    });

    expect(findLockIcon().exists()).toBe(true);
  });

  it('Displays the runner type', () => {
    createComponent({
      runnerType: INSTANCE_TYPE,
      locked: true,
    });

    expect(wrapper.text()).toContain(I18N_INSTANCE_TYPE);
  });

  it('Displays the runner version', () => {
    expect(wrapper.text()).toContain(mockRunner.version);
  });

  it('Displays the runner description', () => {
    expect(wrapper.text()).toContain(mockRunner.description);
  });

  it('Displays the no runner description', () => {
    createComponent({
      description: null,
    });

    expect(wrapper.text()).toContain(I18N_NO_DESCRIPTION);
  });

  it('Displays job execution status', () => {
    expect(findRunnerJobStatusBadge().props('jobStatus')).toBe(mockRunner.jobExecutionStatus);
  });

  it('Displays last contact', () => {
    createComponent({
      contactedAt: '2022-01-02',
    });

    expect(findRunnerSummaryField('clock').findComponent(TimeAgo).props('time')).toBe('2022-01-02');
  });

  it('Displays empty last contact', () => {
    createComponent({
      contactedAt: null,
    });

    expect(findRunnerSummaryField('clock').findComponent(TimeAgo).exists()).toBe(false);
    expect(findRunnerSummaryField('clock').text()).toContain(__('Never'));
  });

  it('Displays ip address', () => {
    createComponent({
      ipAddress: '127.0.0.1',
    });

    expect(findRunnerSummaryField('disk').text()).toContain('127.0.0.1');
  });

  it('Displays no ip address', () => {
    createComponent({
      ipAddress: null,
    });

    expect(findRunnerSummaryField('disk')).toBeUndefined();
  });

  it('Displays job count', () => {
    expect(findRunnerSummaryField('pipeline').text()).toContain(`${mockRunner.jobCount}`);
  });

  it('Formats large job counts', () => {
    createComponent({
      jobCount: 1000,
    });

    expect(findRunnerSummaryField('pipeline').text()).toContain('1,000');
  });

  it('Formats large job counts with a plus symbol', () => {
    createComponent({
      jobCount: 1001,
    });

    expect(findRunnerSummaryField('pipeline').text()).toContain('1,000+');
  });

  it('Displays created at', () => {
    expect(findRunnerSummaryField('calendar').findComponent(TimeAgo).props('time')).toBe(
      mockRunner.createdAt,
    );
  });

  it('Displays tag list', () => {
    createComponent({
      tagList: ['shell', 'linux'],
    });

    expect(findRunnerTags().props('tagList')).toEqual(['shell', 'linux']);
  });

  it.each(['runner-name', 'runner-job-status-badge'])('Displays a custom "%s" slot', (slotName) => {
    const slotContent = 'My custom runner name';

    createComponent(
      {},
      {
        slots: {
          [slotName]: slotContent,
        },
      },
    );

    expect(wrapper.text()).toContain(slotContent);
  });
});
