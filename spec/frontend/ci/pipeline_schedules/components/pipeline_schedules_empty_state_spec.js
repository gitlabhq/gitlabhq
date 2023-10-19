import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import PipelineSchedulesEmptyState from '~/ci/pipeline_schedules/components/pipeline_schedules_empty_state.vue';

describe('Pipeline Schedules Empty State', () => {
  let wrapper;

  const mockSchedulePath = 'root/test/-/pipeline_schedules/new"';

  const createComponent = () => {
    wrapper = shallowMount(PipelineSchedulesEmptyState, {
      provide: {
        newSchedulePath: mockSchedulePath,
      },
      stubs: { GlSprintf },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('shows empty state', () => {
    expect(findEmptyState().exists()).toBe(true);
  });

  it('has link to create new schedule', () => {
    expect(findEmptyState().props('primaryButtonLink')).toBe(mockSchedulePath);
  });

  it('has link to help documentation', () => {
    expect(findLink().attributes('href')).toBe('/help/ci/pipelines/schedules');
  });
});
