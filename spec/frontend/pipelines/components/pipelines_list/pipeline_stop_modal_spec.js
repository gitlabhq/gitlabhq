import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import PipelineStopModal from '~/ci/pipeline_details/pipelines_list/components/pipeline_stop_modal.vue';
import { mockPipelineHeader } from '../../mock_data';

describe('PipelineStopModal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineStopModal, {
      propsData: {
        pipeline: mockPipelineHeader,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should render "stop pipeline" warning', () => {
    expect(wrapper.text()).toMatch(`You’re about to stop pipeline #${mockPipelineHeader.id}.`);
  });
});
