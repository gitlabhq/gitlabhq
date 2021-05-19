import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JobsTableEmptyState from '~/jobs/components/table/jobs_table_empty_state.vue';

describe('Jobs table empty state', () => {
  let wrapper;

  const pipelineEditorPath = '/root/project/-/ci/editor';
  const emptyStateSvgPath = 'assets/jobs-empty-state.svg';

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = () => {
    wrapper = shallowMount(JobsTableEmptyState, {
      provide: {
        pipelineEditorPath,
        emptyStateSvgPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays empty state', () => {
    expect(findEmptyState().exists()).toBe(true);
  });

  it('links to the pipeline editor', () => {
    expect(findEmptyState().props('primaryButtonLink')).toBe(pipelineEditorPath);
  });

  it('shows an empty state image', () => {
    expect(findEmptyState().props('svgPath')).toBe(emptyStateSvgPath);
  });
});
