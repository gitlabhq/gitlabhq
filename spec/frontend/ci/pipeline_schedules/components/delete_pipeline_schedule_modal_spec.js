import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import DeletePipelineScheduleModal from '~/ci/pipeline_schedules/components/delete_pipeline_schedule_modal.vue';

describe('Delete pipeline schedule modal', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DeletePipelineScheduleModal, {
      propsData: {
        visible: true,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    createComponent();
  });

  it('emits the deleteSchedule event', () => {
    findModal().vm.$emit('primary');

    expect(wrapper.emitted()).toEqual({ deleteSchedule: [[]] });
  });

  it('emits the hideModal event', () => {
    findModal().vm.$emit('hide');

    expect(wrapper.emitted()).toEqual({ hideModal: [[]] });
  });
});
