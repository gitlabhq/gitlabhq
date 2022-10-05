import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineScheduleActions from '~/pipeline_schedules/components/table/cells/pipeline_schedule_actions.vue';
import { mockPipelineScheduleNodes, mockPipelineScheduleAsGuestNodes } from '../../../mock_data';

describe('Pipeline schedule actions', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[0],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMount(PipelineScheduleActions, {
      propsData: {
        ...props,
      },
    });
  };

  const findAllButtons = () => wrapper.findAllComponents(GlButton);

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
});
