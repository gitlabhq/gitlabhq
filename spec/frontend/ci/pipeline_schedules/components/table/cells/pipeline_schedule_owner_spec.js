import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineScheduleOwner from '~/ci/pipeline_schedules/components/table/cells/pipeline_schedule_owner.vue';
import { mockPipelineScheduleNodes } from '../../../mock_data';

const mockSchedule = mockPipelineScheduleNodes[0];

describe('Pipeline schedule owner', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(PipelineScheduleOwner, {
      propsData: {
        schedule: mockSchedule,
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
    expect(findAvatar().props('src')).toBe(mockSchedule.owner.avatarUrl);
  });

  it('avatar links to user', () => {
    expect(findAvatarLink().attributes('href')).toBe(mockSchedule.owner.webPath);
  });

  describe('when owner is missing', () => {
    beforeEach(() => {
      createComponent({
        props: {
          schedule: {
            ...mockSchedule,
            owner: null,
          },
        },
      });
    });

    it('displays empty component', () => {
      expect(findAvatar().exists()).toBe(false);
    });
  });
});
