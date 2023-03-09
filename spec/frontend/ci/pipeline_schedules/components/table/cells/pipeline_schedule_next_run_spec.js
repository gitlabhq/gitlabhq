import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineScheduleNextRun from '~/ci/pipeline_schedules/components/table/cells/pipeline_schedule_next_run.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockPipelineScheduleNodes } from '../../../mock_data';

describe('Pipeline schedule next run', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[0],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMountExtended(PipelineScheduleNextRun, {
      propsData: {
        ...props,
      },
    });
  };

  const findTimeAgo = () => wrapper.findComponent(TimeAgoTooltip);
  const findInactive = () => wrapper.findByTestId('pipeline-schedule-inactive');

  it('displays time ago', () => {
    createComponent();

    expect(findTimeAgo().exists()).toBe(true);
    expect(findInactive().exists()).toBe(false);
    expect(findTimeAgo().props('time')).toBe(defaultProps.schedule.realNextRun);
  });

  it('displays inactive state', () => {
    const inactiveSchedule = mockPipelineScheduleNodes[1];
    createComponent({ schedule: inactiveSchedule });

    expect(findInactive().text()).toBe('Inactive');
    expect(findTimeAgo().exists()).toBe(false);
  });
});
