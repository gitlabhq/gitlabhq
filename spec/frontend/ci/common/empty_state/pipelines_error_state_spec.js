import { GlEmptyState } from '@gitlab/ui';
import ERROR_STATE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-failed-md.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesErrorState from '~/ci/common/empty_state/pipelines_error_state.vue';

describe('PipelinesErrorState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = () => {
    wrapper = shallowMountExtended(PipelinesErrorState);
  };

  it('renders the failed-job illustration', () => {
    createComponent();

    expect(findEmptyState().props('svgPath')).toBe(ERROR_STATE_SVG);
  });

  it('renders the error title and description', () => {
    createComponent();

    expect(findEmptyState().props()).toMatchObject({
      title: 'There was an error fetching the pipelines.',
      description: 'Try again in a few moments or contact your support team.',
    });
  });
});
