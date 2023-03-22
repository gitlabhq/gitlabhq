import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import TakeOwnershipModal from '~/ci/pipeline_schedules/components/take_ownership_modal.vue';

describe('Take ownership modal', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TakeOwnershipModal, {
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

  it('shows a take ownership message', () => {
    expect(findModal().text()).toBe(
      'Only the owner of a pipeline schedule can make changes to it. Do you want to take ownership of this schedule?',
    );
  });

  it('emits the takeOwnership event', () => {
    findModal().vm.$emit('primary');

    expect(wrapper.emitted()).toEqual({ takeOwnership: [[]] });
  });

  it('emits the hideModal event', () => {
    findModal().vm.$emit('hide');

    expect(wrapper.emitted()).toEqual({ hideModal: [[]] });
  });
});
