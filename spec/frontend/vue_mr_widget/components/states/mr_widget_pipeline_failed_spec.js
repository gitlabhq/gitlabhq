import { shallowMount } from '@vue/test-utils';
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import PipelineFailed from '~/vue_merge_request_widget/components/states/pipeline_failed.vue';

describe('PipelineFailed', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineFailed);
  };

  const findStatusIcon = () => wrapper.find(statusIcon);

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

  it('merge button should be disabled', () => {
    expect(findStatusIcon().props('showDisabledButton')).toBe(true);
  });
});
