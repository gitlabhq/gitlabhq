import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineScheduleActions from '~/ci/pipeline_schedules/components/table/cells/pipeline_schedule_actions.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  mockPipelineScheduleNodes,
  mockPipelineScheduleCurrentUser,
  mockPipelineScheduleAsGuestNodes,
  mockTakeOwnershipNodes,
} from '../../../mock_data';

describe('Pipeline schedule actions', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[0],
    currentUser: mockPipelineScheduleCurrentUser,
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
  const findTakeOwnershipBtn = () => wrapper.findByTestId('take-ownership-pipeline-schedule-btn');
  const findPlayScheduleBtn = () => wrapper.findByTestId('play-pipeline-schedule-btn');
  const findEditScheduleBtn = () => wrapper.findByTestId('edit-pipeline-schedule-btn');

  it('displays buttons when user is the owner of schedule and has adminPipelineSchedule permissions', () => {
    createComponent();

    expect(findAllButtons()).toHaveLength(3);
  });

  it('does not display action buttons when user is not owner and does not have adminPipelineSchedule permission', () => {
    createComponent({
      schedule: mockPipelineScheduleAsGuestNodes[0],
      currentUser: mockPipelineScheduleCurrentUser,
    });

    expect(findAllButtons()).toHaveLength(0);
  });

  it('delete button emits showDeleteModal event and schedule id', () => {
    createComponent();

    findDeleteBtn().vm.$emit('click');

    expect(wrapper.emitted()).toEqual({
      showDeleteModal: [[mockPipelineScheduleNodes[0].id]],
    });
  });

  it('take ownership button emits showTakeOwnershipModal event and schedule id', () => {
    createComponent({
      schedule: mockTakeOwnershipNodes[0],
      currentUser: mockPipelineScheduleCurrentUser,
    });

    findTakeOwnershipBtn().vm.$emit('click');

    expect(wrapper.emitted()).toEqual({
      showTakeOwnershipModal: [[mockTakeOwnershipNodes[0].id]],
    });
  });

  it('play button emits playPipelineSchedule event and schedule id', () => {
    createComponent();

    findPlayScheduleBtn().vm.$emit('click');

    expect(wrapper.emitted()).toEqual({
      playPipelineSchedule: [[mockPipelineScheduleNodes[0].id]],
    });
  });

  it('edit button links to edit schedule path', () => {
    createComponent();

    const { schedule } = defaultProps;
    const id = getIdFromGraphQLId(schedule.id);

    const expectedPath = `${schedule.editPath}?id=${id}`;

    expect(findEditScheduleBtn().attributes('href')).toBe(expectedPath);
  });
});
