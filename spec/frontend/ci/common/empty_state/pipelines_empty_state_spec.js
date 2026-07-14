import { GlEmptyState } from '@gitlab/ui';
import EMPTY_PIPELINE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';

describe('PipelinesEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(PipelinesEmptyState, {
      propsData: props,
      slots,
    });
  };

  it('renders the empty-pipeline illustration', () => {
    createComponent();

    expect(findEmptyState().props('svgPath')).toBe(EMPTY_PIPELINE_SVG);
  });

  it('forwards the title and description props', () => {
    createComponent({
      props: { title: 'No pipelines', description: 'Nothing here yet' },
    });

    expect(findEmptyState().props()).toMatchObject({
      title: 'No pipelines',
      description: 'Nothing here yet',
    });
  });

  it('renders the description slot when provided', () => {
    createComponent({
      slots: { description: '<span data-testid="custom-description">Rich</span>' },
    });

    expect(wrapper.findByTestId('custom-description').exists()).toBe(true);
  });

  it('renders the actions slot when provided', () => {
    createComponent({ slots: { actions: '<button data-testid="custom-action">Run</button>' } });

    expect(wrapper.findByTestId('custom-action').exists()).toBe(true);
  });
});
