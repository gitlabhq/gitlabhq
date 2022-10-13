import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineScheduleActions from '~/pipeline_schedules/components/table/cells/pipeline_schedule_actions.vue';
import { mockPipelineScheduleNodes, mockPipelineScheduleAsGuestNodes } from '../../../mock_data';

describe('Pipeline schedule actions', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[0],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMountExtended(PipelineScheduleActions, {
      propsData: {
        ...props,
      },
    });
  };

  const findAllButtons = () => wrapper.findAllComponents(GlButton);
  const findDeleteBtn = () => wrapper.findByTestId('delete-pipeline-schedule-btn');

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays action buttons', () => {
    createComponent();

    expect(findAllButtons()).toHaveLength(3);
  });

  it('does not display action buttons', () => {
    createComponent({ schedule: mockPipelineScheduleAsGuestNodes[0] });

    expect(findAllButtons()).toHaveLength(0);
  });

  it('delete button emits showDeleteModal event and schedule id', () => {
    createComponent();

    findDeleteBtn().vm.$emit('click');

    expect(wrapper.emitted()).toEqual({
      showDeleteModal: [[mockPipelineScheduleNodes[0].id]],
    });
  });
});
