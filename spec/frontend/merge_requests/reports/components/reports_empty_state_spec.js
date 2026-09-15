import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReportsEmptyState from '~/merge_requests/reports/components/reports_empty_state.vue';

const PIPELINE_PATH = '/gitlab-org/gitlab/-/pipelines/1';

describe('Merge request reports empty state', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = (propsData) => {
    wrapper = shallowMount(ReportsEmptyState, { propsData });
  };

  it.each([
    [
      'no-pipeline',
      'empty-pipeline-md',
      {
        title: 'No pipeline results yet',
        description: 'Start a pipeline to generate reports.',
        primaryButtonText: 'View CI/CD documentation',
        primaryButtonLink: '/help/ci/_index',
      },
    ],
    [
      'pipeline-running',
      'empty-job-pending-md',
      {
        title: 'Pipeline is running',
        description:
          'Reports appear here when the pipeline finishes. This page updates automatically.',
        primaryButtonText: 'View running pipeline',
        primaryButtonLink: PIPELINE_PATH,
      },
    ],
    [
      'no-reports',
      'empty-artifacts-md',
      {
        title: 'No scanning jobs configured',
        description: 'Add a scanning job to your CI/CD pipeline to see reports here.',
        primaryButtonText: 'View reports documentation',
        primaryButtonLink: '/help/user/project/merge_requests/reports',
      },
    ],
  ])('renders the %s state', (type, svg, expectedProps) => {
    createComponent({ type, pipelinePath: PIPELINE_PATH });

    expect(findEmptyState().props()).toMatchObject(expectedProps);
    expect(findEmptyState().props('svgPath')).toContain(svg);
  });

  it('renders no button link when the pipeline path is missing', () => {
    createComponent({ type: 'pipeline-running' });

    expect(findEmptyState().props('primaryButtonLink')).toBe('');
  });
});
