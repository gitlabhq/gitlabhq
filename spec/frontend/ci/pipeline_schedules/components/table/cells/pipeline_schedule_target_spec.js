import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineScheduleTarget from '~/ci/pipeline_schedules/components/table/cells/pipeline_schedule_target.vue';
import { mockPipelineScheduleNodes } from '../../../mock_data';

describe('Pipeline schedule target', () => {
  let wrapper;

  const defaultProps = {
    schedule: mockPipelineScheduleNodes[0],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMount(PipelineScheduleTarget, {
      propsData: {
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findTarget = () => wrapper.findComponent('[data-testid="pipeline-schedule-target"]');

  describe('with ref', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays icon', () => {
      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props('name')).toBe('fork');
    });

    it('displays ref link', () => {
      expect(findLink().attributes('href')).toBe(defaultProps.schedule.refPath);
      expect(findLink().text()).toBe(defaultProps.schedule.refForDisplay);
    });
  });

  describe('without refPath', () => {
    beforeEach(() => {
      createComponent({
        schedule: { ...mockPipelineScheduleNodes[0], refPath: null, refForDisplay: null },
      });
    });

    it('displays none for the target', () => {
      expect(findIcon().exists()).toBe(false);
      expect(findLink().exists()).toBe(false);
      expect(findTarget().text()).toBe('None');
    });
  });
});
