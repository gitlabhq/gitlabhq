import { shallowMount } from '@vue/test-utils';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { mockPipelineHeader } from 'jest/ci/pipeline_details/mock_data';
import PipelineStopModal from '~/ci/pipelines_page/components/pipeline_stop_modal.vue';

describe('PipelineStopModal', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineStopModal, {
      propsData: {
        pipeline: mockPipelineHeader,
        showConfirmationModal: false,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    createComponent();
  });

  describe('when `showConfirmationModal` is false', () => {
    it('passes the visiblity value to the modal', () => {
      expect(findModal().props().visible).toBe(false);
    });
  });

  describe('when `showConfirmationModal` is true', () => {
    beforeEach(() => {
      createComponent({ props: { showConfirmationModal: true } });
    });

    it('passes the visiblity value to the modal', () => {
      expect(findModal().props().visible).toBe(true);
    });

    it('renders "stop pipeline" warning', () => {
      expect(wrapper.text()).toMatch(`You're about to stop pipeline #${mockPipelineHeader.id}.`);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent({ props: { showConfirmationModal: true } });
    });

    it('emits the close-modal event when the visiblity changes', async () => {
      expect(wrapper.emitted('close-modal')).toBeUndefined();

      await findModal().vm.$emit('change', false);

      expect(wrapper.emitted('close-modal')).toEqual([[]]);
    });
  });
});
