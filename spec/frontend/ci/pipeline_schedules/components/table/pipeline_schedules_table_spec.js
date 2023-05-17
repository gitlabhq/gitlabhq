import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineSchedulesTable from '~/ci/pipeline_schedules/components/table/pipeline_schedules_table.vue';
import { mockPipelineScheduleNodes, mockPipelineScheduleCurrentUser } from '../../mock_data';

describe('Pipeline schedules table', () => {
  let wrapper;

  const defaultProps = {
    schedules: mockPipelineScheduleNodes,
    currentUser: mockPipelineScheduleCurrentUser,
  };

  const createComponent = (props = defaultProps) => {
    wrapper = mountExtended(PipelineSchedulesTable, {
      propsData: {
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findScheduleDescription = () => wrapper.findByTestId('pipeline-schedule-description');

  beforeEach(() => {
    createComponent();
  });

  it('displays table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('displays schedule description', () => {
    expect(findScheduleDescription().text()).toBe('pipeline schedule');
  });
});
