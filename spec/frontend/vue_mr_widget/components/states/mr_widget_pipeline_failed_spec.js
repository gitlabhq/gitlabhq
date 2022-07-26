import { shallowMount } from '@vue/test-utils';
import PipelineFailed from '~/vue_merge_request_widget/components/states/pipeline_failed.vue';

describe('PipelineFailed', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineFailed);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render error message with a disabled merge button', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
