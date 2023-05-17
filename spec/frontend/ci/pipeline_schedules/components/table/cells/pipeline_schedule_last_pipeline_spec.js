import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import PipelineScheduleLastPipeline from '~/ci/pipeline_schedules/components/table/cells/pipeline_schedule_last_pipeline.vue';
import { mockPipelineScheduleNodes } from '../../../mock_data';

describe('Pipeline schedule last pipeline', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[2],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMountExtended(PipelineScheduleLastPipeline, {
      propsData: {
        ...props,
      },
    });
  };

  const findCIBadgeLink = () => wrapper.findComponent(CiBadgeLink);
  const findStatusText = () => wrapper.findByTestId('pipeline-schedule-status-text');

  it('displays pipeline status', () => {
    createComponent();

    expect(findCIBadgeLink().exists()).toBe(true);
    expect(findCIBadgeLink().props('status')).toBe(
      defaultProps.schedule.lastPipeline.detailedStatus,
    );
    expect(findStatusText().exists()).toBe(false);
  });

  it('displays "none" status text', () => {
    createComponent({ schedule: mockPipelineScheduleNodes[0] });

    expect(findStatusText().text()).toBe('None');
    expect(findCIBadgeLink().exists()).toBe(false);
  });
});
