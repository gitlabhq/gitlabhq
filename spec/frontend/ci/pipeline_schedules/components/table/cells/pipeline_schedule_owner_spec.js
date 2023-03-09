import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineScheduleOwner from '~/ci/pipeline_schedules/components/table/cells/pipeline_schedule_owner.vue';
import { mockPipelineScheduleNodes } from '../../../mock_data';

describe('Pipeline schedule owner', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[0],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMount(PipelineScheduleOwner, {
      propsData: {
        ...props,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);

  beforeEach(() => {
    createComponent();
  });

  it('displays avatar', () => {
    expect(findAvatar().exists()).toBe(true);
    expect(findAvatar().props('src')).toBe(defaultProps.schedule.owner.avatarUrl);
  });

  it('avatar links to user', () => {
    expect(findAvatarLink().attributes('href')).toBe(defaultProps.schedule.owner.webPath);
  });
});
